# generated by wxGlade 0.4cvs on Sun Jul 31 15:29:31 2005
# To get wxPerl visit http://wxPerl.sourceforge.net/

use Wx 0.15 qw[:allclasses];
use strict;

package main;

our $config;

package MaintAccFrame;

use Wx qw[:everything];
use base qw(Wx::Frame);
use strict;

# begin wxGlade: ::dependencies
use Wx::Locale gettext => '_T';
# end wxGlade

use AccTreeCtrl;
use EB::Finance;

sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: MaintAccFrame::new

	$style = wxDEFAULT_FRAME_STYLE 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	

	# Menu Bar

	$self->{acc_frame_menubar} = Wx::MenuBar->new();
	$self->SetMenuBar($self->{acc_frame_menubar});
	my $wxglade_tmp_menu;
	$wxglade_tmp_menu = Wx::Menu->new();
	$wxglade_tmp_menu->Append(Wx::NewId(), "Nieuw ...", "");
	$wxglade_tmp_menu->Append(Wx::NewId(), "Open ...", "");
	$wxglade_tmp_menu->Append(Wx::NewId(), "Sluiten", "");
	$wxglade_tmp_menu->AppendSeparator();
	$wxglade_tmp_menu->Append(Wx::NewId(), "Instellingen", "");
	$wxglade_tmp_menu->AppendSeparator();
	$wxglade_tmp_menu->Append(wxID_CLOSE, "E&xit\tAlt-x", "");
	$self->{acc_frame_menubar}->Append($wxglade_tmp_menu, "&Bestand");
	$wxglade_tmp_menu = Wx::Menu->new();
	$wxglade_tmp_menu->Append(Wx::NewId(), "Knip", "");
	$wxglade_tmp_menu->Append(Wx::NewId(), "Plak", "");
	$wxglade_tmp_menu->Append(Wx::NewId(), "Kopi�er", "");
	$self->{acc_frame_menubar}->Append($wxglade_tmp_menu, "&Edit");
	$wxglade_tmp_menu = Wx::Menu->new();
	$wxglade_tmp_menu->Append(Wx::NewId(), "Grootboekrekeningen", "");
	$wxglade_tmp_menu->Append(Wx::NewId(), "Relaties", "");
	$wxglade_tmp_menu->Append(Wx::NewId(), "BTW Tarieven", "");
	$self->{acc_frame_menubar}->Append($wxglade_tmp_menu, "&Onderhoud");
	$wxglade_tmp_menu = Wx::Menu->new();
	$self->{acc_frame_menubar}->Append($wxglade_tmp_menu, "&Dagboeken");
	$wxglade_tmp_menu = Wx::Menu->new();
	$wxglade_tmp_menu->Append(Wx::NewId(), "Proef- en Saldibalans", "");
	$wxglade_tmp_menu->Append(Wx::NewId(), "Balans", "");
	$wxglade_tmp_menu->Append(Wx::NewId(), "Resultaatrekening", "");
	$wxglade_tmp_menu->AppendSeparator();
	$wxglade_tmp_menu->Append(Wx::NewId(), "Grootboek", "");
	$wxglade_tmp_menu->Append(Wx::NewId(), "Journaal", "");
	$wxglade_tmp_menu->Append(Wx::NewId(), "BTW aangifte", "");
	$wxglade_tmp_menu->AppendSeparator();
	$wxglade_tmp_menu->Append(Wx::NewId(), "Debiteuren", "");
	$wxglade_tmp_menu->Append(Wx::NewId(), "Crediteuren", "");
	$self->{acc_frame_menubar}->Append($wxglade_tmp_menu, "Rapportages");
	$wxglade_tmp_menu = Wx::Menu->new();
	$wxglade_tmp_menu->Append(wxID_ABOUT, "&Info", "");
	$self->{acc_frame_menubar}->Append($wxglade_tmp_menu, "&Hulp");
	
# Menu Bar end

	$self->{acc_frame_statusbar} = $self->CreateStatusBar(1, 0);
	$self->{eb_logo} = Wx::StaticBitmap->new($self, -1, Wx::Bitmap->new("/home/jv/src/eekboek/GUI/eb.jpg", wxBITMAP_TYPE_ANY),wxDOUBLE_BORDER);

	$self->__set_properties();
	$self->__do_layout();

# end wxGlade

	$self->{maint_pane}->Enable(0);

	my $sth = $::dbh->sql_exec("SELECT btw_id,btw_desc FROM BTWTabel ORDER BY btw_id");
	my @a;
	my $i = 0;
	my $fmt = "%2d    %s";
	while ( my $rr = $sth->fetchrow_arrayref ) {
	    while ( $i < $rr->[0] ) {
		$a[$i] = sprintf($fmt, $i, "<< Ongebruikt >>");
		$i++;
	    }
	    $a[$rr->[0]] = sprintf($fmt, $rr->[0], $rr->[1]);
	    $i++;
	}
	$self->{ch_btw} = Wx::Choice->new($self->{maint_pane}, -1,
					  wxDefaultPosition, wxDefaultSize,
					  [@a], );
	$self->{sz_btw}->Add($self->{ch_btw}, 1, wxEXPAND, 0);
	$self->{sz_btw}->Layout;

	use Wx::Event qw(EVT_MENU);

	my $closehandler = sub {
	    my ($self, $event) = @_;
	    my @a = $self->GetPositionXY;
	    $config->set("xpos", $a[0]);
	    $config->set("ypos", $a[1]);
	    @a = $self->GetSizeWH;
	    $config->set("xwidth", $a[0]);
	    $config->set("ywidth", $a[1]);

#	    # Explicitly destroy the hidden (but still alive!) dialogs.
#	    foreach ( qw(search select filedialog dirdialog) ) {
#		next unless $self->{"d_$_"};
#		$self->{"d_$_"}->Destroy;
#	    }
	};

	EVT_MENU($self, wxID_CLOSE,
		 sub {
		     my ($self, $event) = @_;
		     $closehandler->(@_);
		     $self->Close(1);
		 });

	use Wx::Event qw(EVT_SPLITTER_SASH_POS_CHANGED);

	EVT_SPLITTER_SASH_POS_CHANGED($self->{w_acc_frame},
				      $self->{w_acc_frame},
				      sub {
					  my ($self, $event) = @_;
					  warn("sash = ", $self->GetSashPosition, "\n");
					  $config->set("sash1", $self->GetSashPosition);
				      });

	EVT_MENU($self, wxID_ABOUT,
		 sub {
		     Wx::MessageBox("$::appname -- Squirrel Consultancy\n".
				    "wxPerl version $Wx::VERSION\n".
				    "wxWidgets version ".Wx::wxVERSION,
				    "Info...",
				    wxOK,
				    $self);
		 });


	return $self;

}


sub __set_properties {
	my $self = shift;

# begin wxGlade: MaintAccFrame::__set_properties

	$self->SetTitle("EekBoek");
	$self->SetBackgroundColour(Wx::Colour->new(255, 255, 255));
	$self->{acc_frame_statusbar}->SetStatusWidths(-1);
	
	my( @acc_frame_statusbar_fields ) = (
		"� 2005 Squirrel Consultancy"
	);

	if( @acc_frame_statusbar_fields ) {
		$self->{acc_frame_statusbar}->SetStatusText($acc_frame_statusbar_fields[$_], $_) 	
		for 0 .. $#acc_frame_statusbar_fields ;
	}

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: MaintAccFrame::__do_layout

	$self->{sz_main} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sz_main}->Add(120, 20, 0, wxEXPAND|wxADJUST_MINSIZE, 1);
	$self->{sz_main}->Add($self->{eb_logo}, 0, wxALL|wxALIGN_CENTER_HORIZONTAL|wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 40);
	$self->{sz_main}->Add(120, 20, 1, wxEXPAND|wxADJUST_MINSIZE, 0);
	$self->SetAutoLayout(1);
	$self->SetSizer($self->{sz_main});
	$self->{sz_main}->Fit($self);
	$self->{sz_main}->SetSizeHints($self);
	$self->Layout();
	$self->Centre();

# end wxGlade

	$self->{w_acc_frame}->SetSashPosition($config->sash1);

}

sub _nf {
    my ($v, $debcrd) = @_;
    numfmtw(abs($v)) . " " .
      (($debcrd xor ($v < 0)) ? "Credit" : ($v ? "Debet" : ""));
}

sub set_acc {
    my ($self, $id) = @_;

    my $rr = $::dbh->do("SELECT acc_desc, acc_balres, acc_kstomz, acc_debcrd, acc_btw,".
			" acc_balance, acc_ibalance FROM Accounts".
			" WHERE acc_id = ?", $id);

    $self->{t_acc_id}->SetValue($id);
    $self->{t_acc_desc}->SetValue($rr->[0]);
    $self->{rb_balres}->SetSelection(!$rr->[1]);
    $self->{rb_kstomz}->SetSelection(!$rr->[2]);
    $self->{rb_debcrd}->SetSelection(!$rr->[3]);
    $self->{rb_debcrd}->Show(1);
    $self->{sz_properties}->Layout;
    $self->{ch_btw}->SetSelection($rr->[4]);
    $self->{t_saldo_act}->SetLabel(_nf($rr->[5], $rr->[3]));
    $self->{t_saldo_opening}->SetLabel(_nf($rr->[6], $rr->[3]));

    $self->{sz_acc}->Show($self->{sz_btw}, 1);
    $self->{sz_acc}->Show($self->{sz_saldo}, 1);
    $self->{sz_acc}->Layout;

    $self->{sz_acc_all}->GetStaticBox->SetLabel("Grootboekrekening");

    $self->{b_accept}->Enable(0);
    $self->{b_cancel}->Enable(0);
    $self->{maint_pane}->Enable(1);
}

sub set_vrd {
    my ($self, $id) = @_;

    my $rr = $::dbh->do("SELECT vdi_desc, vdi_balres, vdi_kstomz, vdi_struct".
			" FROM Verdichtingen".
			" WHERE vdi_id = ?", $id);

    $self->{t_acc_id}->SetValue($id);
    $self->{t_acc_desc}->SetValue($rr->[0]);
    $self->{rb_balres}->SetSelection(!$rr->[1]);
    $self->{rb_kstomz}->SetSelection(!$rr->[2]);
    $self->{rb_debcrd}->Show(0);
    $self->{sz_properties}->Layout;

    $self->{sz_acc}->Show($self->{sz_btw}, 0);
    $self->{sz_acc}->Show($self->{sz_saldo}, 0);
    $self->{sz_acc}->Layout;

    $self->{sz_acc_all}->GetStaticBox->SetLabel("Verdichting");

    $self->{b_accept}->Enable(0);
    $self->{b_cancel}->Enable(0);
    $self->{maint_pane}->Enable(1);
}

# end of class MaintAccFrame

1;
