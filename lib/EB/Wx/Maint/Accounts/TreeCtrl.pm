#!/usr/bin/perl

package main;

our $state;
our $dbh;
our $app;

package EB::Wx::Maint::Accounts::TreeCtrl;

use strict;
use base qw(Wx::TreeCtrl);
use Wx qw[:everything];
use EB::Wx::Window;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    my $root = $self->AddRoot("Gegevens", -1, -1);

    foreach ( qw(Balans Resultaat) ) {
	my $handler = "EB::Wx::Maint::Accounts::TreeCtrl::" . $_ . "Handler";
	my $text = $handler->description;
	my $item = $self->AppendItem($root, $text, -1, -1);
	$handler->populate($self, $item);
	$self->Expand($item) if $state->accexp->{$text};
    }

    Wx::Event::EVT_TREE_SEL_CHANGED   ($self, $self, \&OnSelChange);
    Wx::Event::EVT_TREE_ITEM_EXPANDED ($self, $self, \&OnExpand);
    Wx::Event::EVT_TREE_ITEM_COLLAPSED($self, $self, \&OnCollapse);
    Wx::Event::EVT_TREE_ITEM_ACTIVATED($self, $self, \&OnActivate);

    Wx::Event::EVT_TREE_BEGIN_DRAG    ($self, $self, \&OnBeginDrag);
    Wx::Event::EVT_TREE_END_DRAG      ($self, $self, \&OnEndDrag);

=begin ContextMenu

    Wx::Event::EVT_RIGHT_DOWN ($self, \&OnRightClick);

=cut

    Wx::Event::EVT_IDLE($self, \&OnIdle);

    $self;
}

sub OnIdle {
    my ($self) = @_;
    # To handle things you cannot do from inside an event.
    if ( my $fx = $self->{fix} ) {
	$self->{fix} = 0;
	$self->SetItemText(@$fx);
    }
    if ( my $msg = $self->{msg} ) {
	$self->{msg} = 0;
	EB::Wx::MessageDialog($self, @$msg);
    }
}

sub OnBeginDrag {
    my ($self, $event) = @_;
    if ( $event->GetItem != $self->GetRootItem and
	 $self->GetPlData($event->GetItem) and
	 $self->GetPlData($event->GetItem)->[2] >= 0 ) {
	$self->{draggeditem} = $event->GetItem;
	$event->Allow;
    }
    else {
	Wx::LogMessage( "This item can't be dragged" );
    }
}

use Wx qw(wxOK wxICON_HAND);

sub OnEndDrag {
    my ($self, $event) = @_;
    my ($src, $dst) = ( $self->{draggeditem}, $event->GetItem );

    if ( !$dst->IsOk ) {
	Wx::Bell;
	return;
    }

    if ( $app->{TOP}->{d_maccpanel}->changed ) {
	EB::Wx::MessageDialog($self,
			      "Er zijn wijzigingen in het rechter paneel. Gelieve deze eerst te verwerken of te annuleren.",
			     "In gebruik",
			     wxOK|wxICON_ERROR);
	return;
    }

    if ( $self->GetParent($src) == $dst ||
	 $self->GetParent($src) == $self->GetParent($dst) ) {
	Wx::LogMessage("Drop skipped");
	return;
    }

    my $sdata = $self->GetPlData($src);
    my $ddata = $self->GetPlData($dst) || [0,0,-1];

    unless ( $dbh->lookup($sdata->[0], qw(Accounts acc_id acc_balres))
	     ==
	     $dbh->lookup($ddata->[0], qw(Accounts acc_id acc_balres)) ) {
	Wx::LogMessage("Drop skipped");
	return;
    }

    my $stype = $sdata->[2];
    my $dtype = $ddata->[2];

    if ( $dtype == $stype ) {
	$dst = $self->GetParent($dst);
	$ddata = $self->GetPlData($dst) || [0,0,-1];
	$dtype = $ddata->[2];
    }

    if ( $stype == 2 ) {	# Account
	if ( $dtype == 1 ) {	# Verdichting
	    my $text = $self->GetItemText($src);
	    my $it = $self->AppendItem($dst, $text, -1, -1, Wx::TreeItemData->new($sdata));
	    $self->SortChildren($dst);
	    $self->Delete($src);
	    $dbh->begin_work;
	    $dbh->sql_exec("UPDATE Accounts".
			   " SET acc_struct = ?, acc_balres = ?".
			   " WHERE acc_id = ?",
			   $ddata->[0],
			   $dbh->lookup($ddata->[0], qw(Verdichtingen vdi_id vdi_balres)),
			   $sdata->[0],
			  )->finish;
	    $dbh->commit;
	    $app->{TOP}->{d_maccpanel}->set_item($sdata->[0], $sdata->[2], $self, $dst);
	    $self->SelectItem($it, 1);
	}
	else {
	    $self->{msg} = ["Een grootboekrekening kan alleen worden verplaatst naar een verdichting",
			    "Niet hier",
			    wxOK|wxICON_HAND];
	    return;
	}
    }
    elsif ( $stype == 1 ) {	# Verdichting
	if ( $dtype == 0 ) {	# Hoofdverdichting
	    my $text = $self->GetItemText($src);
	    my $new = $self->AppendItem($dst, $text, -1, -1, Wx::TreeItemData->new($sdata));
	    if ( $self->ItemHasChildren($src) ) {
		$self->CopyChildren($src, $new);
	    }
	    $self->SortChildren($dst);
	    $self->Delete($src);
	    my $sbalres = $dbh->lookup($sdata->[0], qw(Verdichtingen vdi_id vdi_balres));
	    my $dbalres = $dbh->lookup($ddata->[0], qw(Verdichtingen vdi_id vdi_balres));
	    $dbh->begin_work;
	    $dbh->sql_exec("UPDATE Verdichtingen".
			   " SET vdi_struct = ?, vdi_balres = ?".
			   " WHERE vdi_id = ?",
			   $ddata->[0], $dbalres, $sdata->[0],
			  )->finish;
	    $dbh->sql_exec("UPDATE Accounts".
			   " SET acc_balres = ?".
			   " WHERE acc_struct = ?",
			   $dbalres, $sdata->[0],
			  )->finish unless $sbalres == $dbalres;
	    $dbh->commit;
	    $app->{TOP}->{d_maccpanel}->set_item($sdata->[0], $sdata->[2], $self, $dst);
	    $self->SelectItem($new, 1);
	}
	else {
	    $self->{msg} = ["Een verdichting kan alleen worden verplaatst naar een hoofdverdichting",
			    "Niet hier",
			    wxOK|wxICON_HAND];
	    return;
	}
    }
    elsif ( $stype == 0 ) {	# Hoofdverdichting
	if ( $dtype == -1 ) {	# Balans/Resultaat
	    my $text = $self->GetItemText($src);
	    my $new = $self->AppendItem($dst, $text, -1, -1, Wx::TreeItemData->new($sdata));
	    if ( $self->ItemHasChildren($src) ) {
		$self->CopyChildren($src, $new);
	    }
	    $self->SortChildren($dst);
	    $self->Delete($src);
	    my $sbalres = $dbh->lookup($sdata->[0], qw(Verdichtingen vdi_id vdi_balres));
	    my $dbalres = $dbh->lookup($ddata->[0], qw(Verdichtingen vdi_id vdi_balres));
	    $dbh->begin_work;
	    $dbh->sql_exec("UPDATE Verdichtingen".
			   " SET vdi_balres = ?".
			   " WHERE vdi_id = ? OR vdi_struct = ?",
			   $dbalres ? 1 : 0, $sdata->[0], $sdata->[0],
			  )->finish;
	    $dbh->sql_exec("UPDATE Accounts".
			   " SET acc_balres = ?".
			   " WHERE acc_struct IN ( SELECT vdi_id FROM Verdichtingen WHERE vdi_struct = ? )",
			   $dbalres ? 1 : 0, $sdata->[0],
			  )->finish unless $sbalres == $dbalres;
	    $dbh->commit;
	}
	else {
	    $self->{msg} = ["Een hoofdverdichting kan alleen worden verplaatst naar de hoofdgroep \"Balansrekeningen\" of \"Resultaatrekeningen\"",
			    "Niet hier",
			    wxOK|wxICON_HAND];
	    return;
	}
    }
    else {
	Wx::LogMessage("Cannot Drop $stype -> $dtype");
    }
}

sub CopyChildren {
    my ($self, $src, $dst) = @_;
    my ($item, $cookie) = $self->GetFirstChild($src);
    while ( $item->IsOk ) {
	my $new = $self->AppendItem($dst,
				    $self->GetItemText($item),
				    -1, -1,
				    Wx::TreeItemData->new($self->GetPlData($item)));
	if ( $self->ItemHasChildren($item) ) {
	    $self->CopyChildren($item, $new);
	}
	($item, $cookie) = $self->GetNextChild($src, $cookie);
    }
    $self->SetItemHasChildren($dst, 1);
    $self->Expand($dst) if $state->accexp->{$self->GetItemText($dst)};
}

sub OnCompareItems {
    my ($self, $item1, $item2) = @_;
    $self->GetPlData($item1)->[0] <=> $self->GetPlData($item2)->[0];
}

sub OnSelChange {
    my ($self, $event) = @_;
    my $item = $event->GetItem;
    my $data = $self->GetPlData($item);
    return unless $data && ref($data);
    return unless UNIVERSAL::can($data, "select");
    $data->select($self, $event);
}

sub OnActivate {
    my ($self, $event) = @_;
    my $item = $event->GetItem;
    my $data = $self->GetPlData($item);
    return unless $data && ref($data);
    return unless UNIVERSAL::can($data, "activate");
    $data->activate($self, $event);
}

sub OnExpand {
    my ($self, $event) = @_;
    my $item = $event->GetItem;
    my $text = $self->GetItemText($item);
    $state->accexp->{$text} = 1;
}

sub OnCollapse {
    my ($self, $event) = @_;
    my $item = $event->GetItem;
    my $text = $self->GetItemText($item);
    $state->accexp->{$text} = 0;
}

=begin ContextMenu

use Wx qw(wxTREE_HITTEST_NOWHERE);

sub OnRightClick {
    my ($self, $event) = @_;
    my ($item, $flags) = $self->HitTest($event->GetPosition);
    return if $flags & wxTREE_HITTEST_NOWHERE;
    $self->SelectItem($item);
    my $data = $self->GetPlData($item);
    my $ctx = UNIVERSAL::can($data, "ctxmenu");
    return unless $ctx;
    $ctx->($data, $event, $self, $item);
}

=cut

package EB::Wx::Maint::Accounts::TreeCtrl::StandardHandler;

use strict;

sub new {
    my ($class, $rr) = @_;
    $class = ref($class) || $class;
    bless [@$rr], $class;
}

sub select {
    my ($self, $ctrl, $event) = @_;
    print STDERR ("SEL: ", $self->[1], "\n");
}

sub activate {
    my ($self, $ctrl, $event) = @_;
    print STDERR ("ACT: ", @_, "\n");
}

=begin ContextMenu

use constant CTXMENU_DELETE    => Wx::NewId();
use constant CTXMENU_NEW       => Wx::NewId();
use constant CTXMENU_RENAME    => Wx::NewId();
use constant CTXMENU_OPEN      => Wx::NewId();
use constant CTXMENU_EXPAND    => Wx::NewId();
use constant CTXMENU_COLLAPSE  => Wx::NewId();

use Wx qw(wxYES_NO wxYES wxNO_DEFAULT wxICON_QUESTION);

use Wx::Event qw(EVT_MENU EVT_TREE_END_LABEL_EDIT);

sub ctxmenu {
    my ($self, $event, $ctl, $item) = @_; # (this instance, click event, tree ctrl, tree item)
    my $ctxmenu = Wx::Menu->new("");
    $ctxmenu->Append(CTXMENU_OPEN,     "Details");
    if ( $ctl->ItemHasChildren($item) ) {
	$ctxmenu->Append(CTXMENU_EXPAND,   "Uitvouwen");
	$ctxmenu->Append(CTXMENU_COLLAPSE, "Dichtvouwen");
    }
#    $ctxmenu->Append(CTXMENU_RENAME,   "Omschrijving wijzigen");
    $ctxmenu->AppendSeparator;
    $ctxmenu->Append(CTXMENU_NEW,      "Nieuw ...");
#    $ctxmenu->AppendSeparator;
#    $ctxmenu->Append(CTXMENU_DELETE,   "Verwijderen");

    EVT_MENU($ctl, CTXMENU_OPEN,     sub { $self->activate($ctl, $item) });
    EVT_MENU($ctl, CTXMENU_EXPAND,   sub { $ctl->Expand($item) });
    EVT_MENU($ctl, CTXMENU_COLLAPSE, sub { $ctl->Collapse($item) });

    EVT_MENU($ctl, CTXMENU_RENAME,
	     sub {
		 my $t = $ctl->GetItemText($item);
		 $t = $1 if $t =~ /^\d+\s+(.*)/;
		 $ctl->SetItemText($item, $t);
		 $ctl->EditLabel($item);
	     });

    EVT_TREE_END_LABEL_EDIT($ctl, $ctl,
			    sub {
				my (undef, $event) = @_;
				if ( $event->IsEditCancelled ) {
				    my $t = $ctl->GetItemText($item);
				    $ctl->SetItemText($item, $self->[0] . "   " . $t);
				    return;
				}

				my $t = $event->GetLabel;
				$self->[1] = $t;
				Wx::LogMessage("New label for %d: %s", $self->[0], $t);
				$dbh->begin_work;
				$dbh->sql_exec("UPDATE Accounts SET acc_desc = ? WHERE acc_id = ?",
					       $self->[1], $self->[0])->finish;
				$dbh->commit;
				# The new text is stored upon completion of this event.
				# Use the IDLE loop to fix the contents.
				$ctl->{fix} = [ $item, $self->[0] . "   " . $t ];

				if ( $app->{TOP}->{d_maccpanel}->curr_id == $self->[0] ) {
				    $app->{TOP}->{d_maccpanel}->set_desc($t);
				}
			    });

    EVT_MENU($ctl, CTXMENU_DELETE,
	     sub {
		 # my ($self, $event) = @_;
		 my ($aid) = $self->[0];
		 my $r = EB::Wx::MessageDialog
		   ($self,
		    "$aid: " . ($self->[1]) . "\n" .
		    "Wilt u deze rekening verwijderen?",
		    "Bevestig",
		    wxYES_NO|wxNO_DEFAULT|wxICON_QUESTION);
		 return unless $r == wxYES;
		 $dbh->begin_work;
		 $dbh->sql_exec("DELETE FROM Accounts WHERE acc_id = ?",
				$aid)->finish;
		 $dbh->commit;
		 $ctl->Delete($item);
	     });

    EVT_MENU($ctl, CTXMENU_NEW,
	     sub {
		 # my ($self, $event) = @_;
		 my $p = $app->{TOP}->{d_maccpanel};
		 $p->newentry($self->[0]);
	     });

    $ctl->PopupMenu($ctxmenu, $event->GetPosition);
}

=cut

package EB::Wx::Maint::Accounts::TreeCtrl::GrootboekHandler;

use strict;
use base qw(EB::Wx::Maint::Accounts::TreeCtrl::StandardHandler);

sub description { "Grootboekrekeningen" }

sub populate {
    my ($self, $ctrl, $parent, $id) = @_;

    my $sth = $dbh->sql_exec("SELECT vdi_id,vdi_desc FROM Verdichtingen".
			       " WHERE vdi_struct ".
			       (defined($id) ? " = $id" : "IS NULL").
			       " AND " .($self->type eq "balans" ? "" : "NOT") . " vdi_balres".
			       " ORDER BY vdi_id");

    my $rr;
    my $rows;

    while ( $rr = $sth->fetchrow_arrayref ) {
	$rows++;
	my $text = "$rr->[0]   $rr->[1]";
	my $item = $ctrl->AppendItem($parent, $text, -1, -1,
					 Wx::TreeItemData->new(__PACKAGE__->new([@$rr,defined($id)])));
	$self->populate($ctrl, $item, $rr->[0]);
	$ctrl->Expand($item) if $state->accexp->{$text};
    }
    unless ( $rows ) {
	$sth->finish;
	$sth = $dbh->sql_exec("SELECT acc_id,acc_desc FROM Accounts".
				" WHERE acc_struct = ?".
				" ORDER BY acc_id", $id);

	while ( $rr = $sth->fetchrow_arrayref ) {
	    my $id = $rr->[0];
	    my $text = $rr->[1];
	    my $item = $ctrl->AppendItem($parent, "$id   $text", -1, -1,
					 Wx::TreeItemData->new(__PACKAGE__->new([@$rr,2])));
	}
    }
}

sub select {
    my ($self, $ctrl, $event) = @_;
    my $item = $event->GetItem;
    my $data = $ctrl->GetPlData($item);
}

sub activate {
    my ($self, $ctrl, $event) = @_;
    my $item = UNIVERSAL::isa($event, 'Wx::TreeItemId') ? $event : $event->GetItem;
    my $data = $ctrl->GetPlData($item);
    $app->{TOP}->{d_maccpanel}->set_item($data->[0], $data->[2], $ctrl, $item);
}

package EB::Wx::Maint::Accounts::TreeCtrl::BalansHandler;

use strict;
use base qw(EB::Wx::Maint::Accounts::TreeCtrl::GrootboekHandler);

sub description { "Balansrekeningen" }

sub type { "balans" };

package EB::Wx::Maint::Accounts::TreeCtrl::ResultaatHandler;

use strict;
use base qw(EB::Wx::Maint::Accounts::TreeCtrl::GrootboekHandler);

sub description { "Resultaatrekeningen" }

sub type { "result" };

1;
