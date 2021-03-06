#! perl

package main;

our $app;
our $state;
our $dbh;

package EB::Wx::UI::StdAccPanel;

use Wx qw[:everything];
use base qw(Wx::Panel);
use strict;
use EB;

# begin wxGlade: ::dependencies
use EB::Wx::UI::BalAccInput;
use EB::Wx::UI::ListInput;
use EB::Wx::Window;
# end wxGlade

sub new {
	my( $self, $parent, $id, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: EB::Wx::UI::StdAccPanel::new

	$self = $self->SUPER::new( $parent, $id, $pos, $size, $style, $name );
	$self->{main_panel} = Wx::ScrolledWindow->new($self, -1, wxDefaultPosition, wxDefaultSize, wxTAB_TRAVERSAL|wxCLIP_CHILDREN);
	$self->{l_winst} = Wx::StaticText->new($self->{main_panel}, -1, _T("Winst"), wxDefaultPosition, wxDefaultSize, );
	$self->{tx_winst} = EB::Wx::UI::BalAccInput->new($self->{main_panel}, -1, "", wxDefaultPosition, wxDefaultSize, );
	$self->{b_apply} = Wx::Button->new($self, wxID_APPLY, "");
	$self->{b_reset} = Wx::Button->new($self, wxID_REVERT_TO_SAVED, "");

	$self->__set_properties();
	$self->__do_layout();

	Wx::Event::EVT_TEXT($self, $self->{tx_winst}->GetId, \&OnChanged);
	Wx::Event::EVT_BUTTON($self, $self->{b_apply}->GetId, \&OnApply);
	Wx::Event::EVT_BUTTON($self, $self->{b_reset}->GetId, \&OnReset);

# end wxGlade

	Wx::Event::EVT_IDLE($self, \&OnIdle);

	$self->refresh;
	my $ch = $self->changed;
	$self->{b_apply}->Enable($ch);
	$self->{b_reset}->Enable($ch);

	return $self;

}


sub __set_properties {
	my $self = shift;

# begin wxGlade: EB::Wx::UI::StdAccPanel::__set_properties

	$self->SetSize($self->ConvertDialogSizeToPixels(Wx::Size->new(187, 153)));
	$self->{l_winst}->Enable(0);
	$self->{tx_winst}->Enable(0);
	$self->{main_panel}->SetScrollRate(10, 10);

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: EB::Wx::UI::StdAccPanel::__do_layout

	$self->{sz_std} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sz_std_buttons} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sz_stdacc} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sz_g_stdacc} = Wx::FlexGridSizer->new(0, 2, 3, 5);
	$self->{sz_g_stdacc}->Add($self->{l_winst}, 0, wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 0);
	$self->{sz_g_stdacc}->Add($self->{tx_winst}, 1, wxEXPAND|wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 0);
	$self->{sz_g_stdacc}->AddGrowableCol(1);
	$self->{sz_stdacc}->Add($self->{sz_g_stdacc}, 0, wxALL|wxEXPAND, 5);
	$self->{main_panel}->SetSizer($self->{sz_stdacc});
	$self->{sz_std}->Add($self->{main_panel}, 1, wxEXPAND, 0);
	$self->{sz_std_buttons}->Add($self->{b_apply}, 0, wxADJUST_MINSIZE, 0);
	$self->{sz_std_buttons}->Add(20, 20, 1, wxADJUST_MINSIZE, 0);
	$self->{sz_std_buttons}->Add($self->{b_reset}, 0, wxADJUST_MINSIZE, 0);
	$self->{sz_std}->Add($self->{sz_std_buttons}, 0, wxALL|wxEXPAND, 5);
	$self->SetSizer($self->{sz_std});

# end wxGlade

	# Bepaal dynamisch de rest van de koppelingen.
	foreach my $acc ( sort @{$dbh->std_accs} ) {
	    next if $acc eq 'winst';
	    my $label = $acc;
	    if ( $acc eq 'deb' ) {
		$label = "Debiteuren";
	    }
	    elsif ( $acc eq 'crd' ) {
		$label = "Crediteuren";
	    }
	    elsif ( $acc eq 'btw_ok' ) {
		$label = "BTW Betaald";
	    }
	    elsif ( $acc =~ /^btw_([iv])(.)$/ ) {
		$label = "BTW ";
		$label .= $1 eq 'i' ? "Inkoop " : "Verkoop ";
		foreach ( @{BTWTARIEVEN()} ) {
		    $label .= $_ if lc(substr($_, 0, 1)) eq $2;
		}
	    }
	    $self->{"l_$acc"} = Wx::StaticText->new($self->{main_panel}, -1, _T($label), wxDefaultPosition, wxDefaultSize, );
	    $self->{"tx_$acc"} = EB::Wx::UI::BalAccInput->new($self->{main_panel}, -1, "", wxDefaultPosition, wxDefaultSize, );
	    $self->{"tx_$acc"}->SetValue($dbh->std_acc($acc));
	    $self->{sz_g_stdacc}->Add($self->{"l_$acc"}, 0, wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 0);
	    $self->{sz_g_stdacc}->Add($self->{"tx_$acc"}, 1, wxEXPAND|wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 0);
	    Wx::Event::EVT_TEXT($self, $self->{"tx_$acc"}->GetId, \&OnChanged);
	}

}

sub hide_buttons {
    my ($self, $hide) = (@_, 1);
    $self->{sz_std}->Show($self->{sz_std_buttons}, !$hide);
    $self->Layout;
}

sub OnIdle {
    my ($self) = @_;
    return unless $self->{_check_changed};
    $self->{_check_changed} = 0;
    my $ch = $self->changed;
    $self->{b_apply}->Enable($ch);
    $self->{b_reset}->Enable($ch);
}

sub refresh {
    my ($self) = @_;
    local($self->{busy}) = 1;
    $self->{anyinuse} = 0;
    foreach my $acc ( @{$dbh->std_accs} ) {
	my $t = $dbh->std_acc($acc);
	$self->{"tx_$acc"}->SetValue($t);
	my $inuse = $dbh->do("SELECT COUNT(*) FROM Journal WHERE jnl_acc_id = ?",
			     $dbh->std_acc($acc))->[0];
	if ( $inuse ) {
	    $self->{"tx_$acc"}->Enable(0);
	    $self->{"l_$acc"}->Enable(0);
	    $self->{anyinuse}++;
	}
	else {
	    $self->{"tx_$acc"}->Enable(1);
	    $self->{"l_$acc"}->Enable(1);
	}
    }
}

sub anyinuse {
    my ($self) = @_;
    $self->{anyinuse};
}

sub changed {
    my ($self) = @_;
    return 0 if $self->{busy};
    foreach my $acc ( @{$dbh->std_accs} ) {
	eval {
	    return 1 if (split(' ', $self->{"tx_$acc"}->GetValue))[0] != $dbh->std_acc($acc);
	};
    }
    return 0;
}

# wxGlade: EB::Wx::UI::StdAccPanel::OnChanged <event_handler>
sub OnChanged {
    my ($self, $event) = @_;
    $self->{_check_changed}++;
}

# wxGlade: EB::Wx::UI::StdAccPanel::OnApply <event_handler>
sub OnApply {
    my ($self, $event) = @_;
    $dbh->begin_work;
    eval { $self->apply };
    if ( $@ ) {
	$dbh->rollback;
	EB::Wx::MessageDialog
	    ($self,
	     "Dat ging niet helemaal lekker.\n".$@,
	     "Oeps",
	     wxOK|wxICON_ERROR);
    }
    else {
	#$dbh->commit;
    }
    $self->{_check_changed}++;
}

sub apply {
    my ($self) = @_;
    my @set;
    my $t;
    foreach my $acc ( @{$dbh->std_accs} ) {
	if ( ($t = (split(' ', $self->{"tx_$acc"}->GetValue))[0]) != $dbh->std_acc($acc) ) {
	    my $inuse = $dbh->do("SELECT COUNT(*) FROM Journal WHERE jnl_acc_id = ?",
				 $t)->[0];
	    if ( $inuse ) {
		EB::Wx::MessageBox
		    ($self,
		     "Rekening $t is in gebruik", "In gebruik",
		     wxOK|wxICON_ERROR);
		next;
	    }
	    push(@set, "std_acc_$acc = $t");
	}
    }

    if ( @set ) {
	$dbh->sql_exec("UPDATE Standaardrekeningen SET ".
		       join(", ", @set))->finish;
	$dbh->commit;
	$dbh->std_acc("");	# slush cache
	$self->refresh;
	$self->{_check_changed} = 1;
    }
}

# wxGlade: EB::Wx::UI::StdAccPanel::OnReset <event_handler>
sub OnReset {
    my ($self, $event) = @_;
    $self->refresh;
}


1;

