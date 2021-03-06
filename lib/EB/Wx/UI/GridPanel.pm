#! perl

# GridPanel.pm -- 
# Author          : Johan Vromans
# Created On      : Wed Aug 24 17:40:46 2005
# Last Modified By: Johan Vromans
# Last Modified On: Sat Jun 19 22:32:11 2010
# Update Count    : 338
# Status          : Unknown, Use with caution!

# GridPanel implements a widget that is row/column oriented, and
# wehere each cell can contain an arbitrary other widget provided it
# implements the GridPanel cell API. Wrappers are provided for some
# common types of widgets.
#
# Why not Wx::Grid? Wx::Grid cell renderers are rather limited, and
# you always need to select a cell first before it can be edited. This
# means clicking twice to toggle a checkbox, which I find very
# counter-intuitive.
#
# I considered Wx::List, but this can only cope with a limited set of
# predefined celltypes.
#
# The biggest disadvantage of GridPanel is that since it provides
# artificial column labels in the first row of the grid, these labels
# scroll away when the grid needs scrolling. Maybe I can find a
# solution for that some day...

package EB::Wx::UI::GridPanel;

use Wx qw[:everything];
use base qw(Wx::Panel);
use strict;
use Carp;
use EB;

use EB::Wx::UI::GridPanel::RemoveButton;

################ API: new ################
#
# Constructor.
# This is fully compliant with wxPanel so you can use tools like
# wxGlade.

sub new {
    my ($self, $parent, $id, $pos, $size, $style, $name) = @_;
    $parent = undef              unless defined $parent;
    $id     = -1                 unless defined $id;
    $pos    = wxDefaultPosition  unless defined $pos;
    $size   = wxDefaultSize      unless defined $size;
    $name   = ""                 unless defined $name;

    $style = wxTAB_TRAVERSAL unless defined $style;

    $self = $self->SUPER::new($parent, $id, $pos, $size, $style, $name);

    $self->{panel} = Wx::ScrolledWindow->new($self, -1,
					     wxDefaultPosition, wxDefaultSize,
					     wxTAB_TRAVERSAL|wxVSCROLL);
    $self->{panel}->SetScrollRate(10, 10);

    $self->{b_apply} = Wx::Button->new($self, wxID_APPLY, "");
    $self->{b_new}   = Wx::Button->new($self, wxID_NEW,   "");
    $self->{b_reset} = Wx::Button->new($self, wxID_REVERT_TO_SAVED,  "");

    $self->{b_apply}->Enable(0);
    $self->{b_new}->Enable(1);
    $self->{b_reset}->Enable(0);

    $self->{sz_buttons} = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sz_buttons}->Add($self->{b_apply}, 0, wxADJUST_MINSIZE, 0);
    $self->{sz_buttons}->Add($self->{b_new}, 0, wxLEFT|wxADJUST_MINSIZE, 5);
    $self->{sz_buttons}->Add(5, 1, 1, wxADJUST_MINSIZE, 0);
    $self->{sz_buttons}->Add($self->{b_reset}, 0, wxADJUST_MINSIZE, 0);

    Wx::Event::EVT_BUTTON($self, wxID_APPLY, \&OnApply);
    Wx::Event::EVT_BUTTON($self, wxID_NEW,   \&OnNew);
    Wx::Event::EVT_BUTTON($self, wxID_UNDO,  \&OnReset);

    $self;
}

################ API: create ################
#
# Creating the internal grid.
#
# The main parameter is an array ref with arguments pairs. The first
# of a pair is the label, the second is either the name of the wrapper
# class, or an array ref with the wrapper class as its first element,
# and and array ref with construction data as the second element.

sub create {
    my ($self, $cols, $vgap, $hgap, $rows) = @_;

    die(__PACKAGE__ . " columns argument must be an array ref")
      unless UNIVERSAL::isa($cols, 'ARRAY');
    die(__PACKAGE__ . " columns argument must contain columns")
      unless @$cols && !(@$cols % 2);

    $self->{cols} = @$cols / 2;
    $vgap = 0 unless defined $vgap;
    $hgap = 0 unless defined $hgap;

    if ( defined $self->{grid} ) {
	# Remove all except the first row (the labels).
	for (my $row = $self->{rows}-1; $row > 0; $row-- ) {
	    for (my $col = $self->{cols}-1; $col >= 0; $col-- ) {
		my $item = $self->item($row,$col);
		next unless $item;
		if ( $self->{grid}->Detach($item) ) {
		    $item->Destroy;
		}
		else {
		    Wx::LogMessage("GridPanel: detach failed: $row $col $item");
		}
		delete($self->{rc($row,$col)});
	    }
	    delete($self->{rx($_, $row)}) foreach qw(b d n x);
	}
    }
    else {
	$self->{grid} = Wx::FlexGridSizer->new($rows||1, $self->{cols}, $vgap, $hgap);
	my $i = 0;
	my $flip = 0;
	foreach my $col ( @$cols ) {
	    if ( $flip ) {
		# Template.
		push(@{$self->{grid_cols}}, $col);
		$i++;
	    }
	    else {
		# Label. Abusing rx ...
		$self->{rx("l", $i)} = Wx::StaticText->new($self->{panel}, -1, $col, wxDefaultPosition, wxDefaultSize, );
		$self->{grid}->Add($self->{rx("l", $i)}, 0, wxLEFT|wxEXPAND|wxADJUST_MINSIZE, 5);
	    }
	    $flip = !$flip;
	}
	$self->{panel}->SetSizer($self->{grid});
	$self->{sz_main} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sz_main}->Add($self->{panel},      1, wxEXPAND|wxADJUST_MINSIZE|wxFIXED_MINSIZE, 0);
	$self->{sz_main}->Add($self->{sz_buttons}, 0, wxTOP|wxEXPAND|wxADJUST_MINSIZE|wxFIXED_MINSIZE, 10);
	$self->SetSizer($self->{sz_main});
	$self->SetAutoLayout(1);
	$self->{sz_main}->SetSizeHints($self);
	Wx::Event::EVT_IDLE($self, \&OnIdle);
    }

    $self->{grid}->SetRows($self->{rows} = 1);
    $self->Layout();
}

################ API: addgrowablecol ################
#
# See wxFlexGridSizer for details.

sub addgrowablecol {
    my ($self) = shift;
    $self->{grid}->AddGrowableCol(@_);
}

################ API: registerapplycb ################
#
# Register the callback for the "Apply" operation.
#
# The callback should return true if the changes are applied successfully.
#
# The callback gets an array refence passed.
#
#  ref -> [ [ <action>, <new contents>, <user data> ], ...]
#
#  action: 0 -> new row
#         -1 -> deleted row
#       else -> changed row, 1 bit per changed column

#### TODO: Use event. See Wx::Perl::VirtualTreeCtrl on CPAN for an example.
#### DONE: Cannot use event -- need return value.
#### TODO: Store return value in event.

sub registerapplycb {
    my ($self, $cb) = @_;
    $self->{applycb} = $cb;
}

################ API: append ################
#
# Append a new row to the grid.
#
# If there are more values supplied than required, the remaining
# values will be stored and passed back when calling the apply
# callback (for identification or so).

sub append {
    my ($self, @values) = @_;
    $self->new_or_append(0, @values);
}

################ API: changed ################
#
# Returns true if any of the items in the grid have changed.

sub changed {
    my ($self) = @_;
    foreach my $row ( 1 .. $self->{rows}-1 ) {
	next unless $self->exists($row);
	return 1 if $self->is_deleted($row) || $self->is_new($row);
	foreach my $col ( 0 .. $self->{cols}-1 ) {
	    my $item = $self->item($row, $col);
	    warn("changed: UNDEFINED ITEM @ $row $col\n") unless $item;
	    next unless $item->changed;
	    return 1;
	}
    }
    undef;
}

################ API: enable ################
#
# Enable/disable columns.

sub enable {
    my ($self, @values) = @_;
    my $row = $self->{rows} - 1;
    foreach my $col ( 0 .. $self->{cols}-1 ) {
	$self->item($row, $col)->Enable($values[$col]);
    }
}

################ Low level services ################

sub rc {
    sprintf("r_%02d_c_%02d", @_);
}

sub rx {
    sprintf("%s_%02d", @_);
}

sub item : lvalue {
    my ($self, $row, $col) = @_;
    $self->{rc($row, $col)};
}

sub rembut : lvalue {
    my ($self, $row) = @_;
    $self->{rx("b", $row)};
}

sub exists {
    my ($self, $row) = @_;
    defined($self->{rx("n", $row)});
}

sub is_new : lvalue {
    my ($self, $row) = @_;
    $self->{rx("n", $row)};
}

sub is_deleted : lvalue {
    my ($self, $row) = @_;
    $self->{rx("x", $row)};
}

sub data : lvalue {
    my ($self, $row) = @_;
    $self->{rx("d", $row)};
}

################ Services ################

sub reset_changes {
    my ($self) = @_;
    foreach my $row ( 1 .. $self->{rows}-1 ) {
	next unless $self->exists($row);
	my $item = $self->rembut($row);
	if ( $item ) { #&& $self->is_deleted($row) && !$self->is_new($row) ) {
	    $item->reset;
	    $self->OnRemoveButton($row);
	}
	foreach my $col ( 0 .. $self->{cols}-1 ) {
	    $item = $self->item($row, $col);
	    warn("reset: UNDEFINED ITEM @ $row $col\n") unless $item;
	    $item->reset;
	}
    }
}

sub perform_update {
    my ($self) = @_;
    my @actions;
    my $rows = $self->{rows};
    foreach my $row ( 1 .. $rows-1 ) {
	next unless $self->exists($row);
	my $rowchanged = 0;
	my $action = 0;
	my @act = (0);
	foreach my $col ( 0 .. $self->{cols}-1 ) {
	    my $item = $self->item($row, $col);
	    push(@act, $item->value);
	    $action |= (1 << $col), $rowchanged++ if $item && $item->changed;
	    $col++;
	}
	warn("row $row: ",
	     $self->is_new($row) ? "new, " : "",
	     $self->is_deleted($row) ? "del, " : "",
	     $rowchanged ? "changed" : "not changed",
	     "\n");
	if ( $self->is_new($row) ) {
	    next if $self->is_deleted($row);
	    $action = 0;
	    $rowchanged++ unless $self->is_deleted($row);
	}
	elsif ( $self->is_deleted($row) ) {
	    $action = -1;
	    $rowchanged++ unless $self->is_new($row);
	}
	$act[0] = $action;
	my $data = $self->data($row);
	push(@act, @$data) if $data;
	push(@actions, [@act]) if $rowchanged;
    }
    use Data::Dumper; warn(Dumper(\@actions));
    if ( $self->{applycb}->(\@actions) ) {
	foreach my $row ( 1 .. $rows-1 ) {
	    next unless $self->exists($row);
	    if ( $self->is_new($row) && !$self->is_deleted($row) ) {
		$self->is_new($row) = 0;
	    }
	}
	return 1;
    }
    undef;
}

sub expunge_rows {
    my ($self) = @_;
    foreach my $row ( 1 .. $self->{rows}-1 ) {
	next unless $self->exists($row);
	next unless ( $self->is_deleted($row) || $self->is_new($row) );
	delete($self->{rx($_, $row)}) foreach qw(n b d x);
	foreach my $col ( 0 .. $self->{cols}-1 ) {
	    my $item = $self->item($row, $col);
	    $self->{grid}->Detach($item) or warn("detach failed ", rc($row, $col), "\n");
	    $item->Destroy;
	    delete($self->{rc($row, $col)});
	}
    }
}

sub commit_changes {
    my ($self) = @_;
    foreach my $row ( 1 .. $self->{rows}-1 ) {
	next unless $self->exists($row);
	foreach my $col ( 0 .. $self->{cols}-1 ) {
	    $self->item($row, $col)->commit;
	}
	$self->is_new($row) = 0;
	$self->is_deleted($row) = 0;
    }
}

sub new_or_append_noupdate {
    my ($self, $new, @values) = @_;
    $self->_new_or_append($new, 1, @values);
}

sub new_or_append {
    my ($self, $new, @values) = @_;
    $self->_new_or_append($new, 0, @values);
}

sub _new_or_append {
    my ($self, $new, $more, @values) = @_;
    if ( $more && $more == 2 ) {
	$self->{grid}->FitInside($self->{panel});
	$self->Layout();
	return;
    }

    my $r = $self->{rows}++;
    my $c = 0;
    my @data;
    foreach my $col ( @{$self->{grid_cols}} ) {
	my $w;
	my $f = $col;
	my @args;
	if ( UNIVERSAL::isa($col, 'ARRAY') ) {
	    ($f, @args) = @$col;
	}
	unless ( $new ) {
	    my $val = shift(@values);
	    push(@data, $val);
	    if ( ref($val) eq 'ARRAY' ) {
		($f, $val) = @$val;
	    }
	    push(@args, $val);
	}

	if ( $f eq EB::Wx::UI::GridPanel::RemoveButton:: ) {
	    $w = $self->rembut($r) = $f->new($self->{panel}, 0);
	    $self->is_deleted($r) = 0;
	    $self->is_new($r) = $new;
	    $w->is_new($new);
	    $w->flip_button($new) if $new;
	    $w->registerchangecallback(sub { $self->OnRemoveButton($r) });
	}
	else {
	    $w = $f->new($self->{panel}, @args);
	    $w->registerchangecallback(sub { $self->{_check_changed}++ });
	}
	$self->item($r, $c) = $w;
	$self->{grid}->Add($w, 0, wxEXPAND|wxALIGN_CENTER_HORIZONTAL|wxADJUST_MINSIZE, 0);
	$c++;
    }
    $self->data($r) = [@data, @values];

    unless ( $more ) {
	$self->{grid}->FitInside($self->{panel});
	$self->Layout();
    }
    $self->{_check_changed}++;
    $r;
}

################ Event handlers ################

sub OnRemoveButton {
    my ($self, $row) = @_;
    my $button = $self->rembut($row);
    $self->is_deleted($row) = $button->value;
    $self->{_check_changed}++;
}

sub OnIdle {
    my ($self) = @_;
    return unless $self->{_check_changed};
    $self->{_check_changed} = 0;
    my $ch = $self->changed;
    $self->{b_apply}->Enable($ch);
    $self->{b_reset}->Enable($ch);
}

sub OnReset {
    my ($self) = @_;

    $self->reset_changes;
    $self->expunge_rows;

    $self->{grid}->FitInside($self->{panel});
    $self->Layout;
    $self->{_check_changed}++;
}

sub OnApply {
    my ($self) = @_;

    if ( $self->perform_update ) {
	$self->expunge_rows;
	$self->commit_changes;
    }

    $self->{grid}->FitInside($self->{panel});
    $self->Layout;
    $self->{_check_changed}++;
}

sub OnNew {
    my ($self) = @_;
    $self->new_or_append(1);
    $self->{panel}->Scroll(-1,9999); #### TODO
}

1;

