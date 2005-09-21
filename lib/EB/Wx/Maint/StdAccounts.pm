# generated by wxGlade 0.4cvs*** on Fri Aug 19 14:45:25 2005
# To get wxPerl visit http://wxPerl.sourceforge.net/

package main;

our $dbh;
our $config;
our $app;

use Wx 0.15 qw[:allclasses];
use strict;
package MStdAccPanel;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use strict;

# begin wxGlade: ::dependencies
use StdAccPanel;
# end wxGlade

sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: MStdAccPanel::new

	$style = wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER|wxTHICK_FRAME 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{stdacc_title_staticbox} = Wx::StaticBox->new($self, -1, _T("Koppelingen") );
	$self->{p_stdacc} = StdAccPanel->new($self, -1);
	$self->{l_inuse} = Wx::StaticText->new($self, -1, _T("Sommige gegevens zijn in gebruik en\nkunnen niet meer worden gewijzigd."), wxDefaultPosition, wxDefaultSize, );
	$self->{b_cancel} = Wx::Button->new($self, wxID_CLOSE, _T("Close"));

	$self->__set_properties();
	$self->__do_layout();

	Wx::Event::EVT_BUTTON($self, wxID_CLOSE, \&OnClose);

# end wxGlade
	$self->{mew} = "stdw";
	return $self;

}

sub __set_properties {
	my $self = shift;

# begin wxGlade: MStdAccPanel::__set_properties

	$self->SetTitle(_T("Koppelingen"));
	$self->{b_cancel}->SetFocus();
	$self->{b_cancel}->SetDefault();

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: MStdAccPanel::__do_layout

	$self->{stdacc_outer} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{stdacc_main} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sz_buttons} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{stdacc_title}= Wx::StaticBoxSizer->new($self->{stdacc_title_staticbox}, wxHORIZONTAL);
	$self->{stdacc_title}->Add($self->{p_stdacc}, 1, wxEXPAND, 0);
	$self->{stdacc_main}->Add($self->{stdacc_title}, 1, wxEXPAND, 0);
	$self->{sz_buttons}->Add($self->{l_inuse}, 0, wxEXPAND|wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 5);
	$self->{sz_buttons}->Add(5, 1, 1, wxEXPAND|wxADJUST_MINSIZE, 0);
	$self->{sz_buttons}->Add($self->{b_cancel}, 0, wxEXPAND|wxADJUST_MINSIZE|wxFIXED_MINSIZE, 5);
	$self->{stdacc_main}->Add($self->{sz_buttons}, 0, wxALL|wxEXPAND, 5);
	$self->{stdacc_outer}->Add($self->{stdacc_main}, 1, wxALL|wxEXPAND, 5);
	$self->SetAutoLayout(1);
	$self->SetSizer($self->{stdacc_outer});
	$self->{stdacc_outer}->Fit($self);
	$self->{stdacc_outer}->SetSizeHints($self);
	$self->Layout();

# end wxGlade
}

# wxGlade: MStdAccPanel::OnClose <event_handler>
sub OnClose {
    my ($self, $event) = @_;
    if ( $self->{p_stdacc}->changed ) {
	my $r = Wx::MessageBox("Er zijn nog wijzigingen, deze zullen verloren gaan.\n".
			       "Venster toch sluiten?",
			       "Annuleren",
			       wxYES_NO|wxNO_DEFAULT|wxICON_ERROR);
	return unless $r == wxYES;
	$self->{p_stdacc}->refresh;
    }
    # Remember position and size.
    @{$config->get($self->{mew})}{qw(xpos ypos xwidth ywidth)} = ($self->GetPositionXY, $self->GetSizeWH);
    # Disappear.
    $self->Show(0);
}

# end of class MStdAccPanel

1;
