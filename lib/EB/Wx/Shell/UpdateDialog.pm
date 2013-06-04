#! perl

package main;

use strict;

package EB::Wx::Shell::UpdateDialog;

use base qw(Wx::Dialog);
use strict;

use Wx qw[:everything];

use Wx::Locale gettext => '_T';

sub new {
    my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
    $parent = undef              unless defined $parent;
    $id     = -1                 unless defined $id;
    $title  = ""                 unless defined $title;
    $pos    = wxDefaultPosition  unless defined $pos;
    $size   = wxDefaultSize      unless defined $size;
    $name   = ""                 unless defined $name;

    # begin wxGlade: EB::Wx::Shell::UpdateDialog::new
    $style = wxDEFAULT_DIALOG_STYLE 
        unless defined $style;

    $self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
    $self->{l_msg} = Wx::StaticText->new($self, wxID_ANY, _T("EekBoek versie x.yy.zz is beschikbaar.\n\nU wordt aangeraden de release notes te lezen en daarna te ugraden."), wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE);
    $self->{hl_relnotes} = Wx::HyperlinkCtrl->new($self, wxID_ANY, _T("Lees de release notes"), _T("http://www.squirrel.nl/relnotes.html"), wxDefaultPosition, wxDefaultSize, wxHL_ALIGN_CENTRE|wxHL_CONTEXTMENU|wxHL_DEFAULT_STYLE);
    $self->{static_line_1} = Wx::StaticLine->new($self, wxID_ANY, wxDefaultPosition, wxDefaultSize, );
    $self->{cb_remind} = Wx::CheckBox->new($self, wxID_ANY, _T("Deze herinnering niet meer tonen"), wxDefaultPosition, wxDefaultSize, );
    $self->{b_ok} = Wx::Button->new($self, wxID_OK, "");

    $self->__set_properties();
    $self->__do_layout();

    Wx::Event::EVT_BUTTON($self, $self->{b_ok}->GetId, \&OnOk);

    # end wxGlade
    return $self;

}

sub __set_properties {
    my $self = shift;
    # begin wxGlade: EB::Wx::Shell::UpdateDialog::__set_properties
    $self->SetTitle(_T("EekBoek Update"));
    # end wxGlade
}

sub __do_layout {
    my $self = shift;
    # begin wxGlade: EB::Wx::Shell::UpdateDialog::__do_layout
    $self->{sz_main} = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sz_contents} = Wx::BoxSizer->new(wxVERTICAL);
    $self->{sz_buttons} = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sz_cb} = Wx::BoxSizer->new(wxHORIZONTAL);
    $self->{sz_contents}->Add($self->{l_msg}, 0, wxBOTTOM|wxADJUST_MINSIZE, 10);
    $self->{sz_contents}->Add($self->{hl_relnotes}, 0, wxEXPAND|wxADJUST_MINSIZE, 0);
    $self->{sz_contents}->Add($self->{static_line_1}, 0, wxALL|wxEXPAND, 10);
    $self->{sz_cb}->Add(5, 1, 1, wxADJUST_MINSIZE, 0);
    $self->{sz_cb}->Add($self->{cb_remind}, 0, wxADJUST_MINSIZE, 0);
    $self->{sz_cb}->Add(5, 1, 1, wxADJUST_MINSIZE, 0);
    $self->{sz_contents}->Add($self->{sz_cb}, 1, wxEXPAND, 0);
    $self->{sz_buttons}->Add(5, 1, 1, wxEXPAND|wxADJUST_MINSIZE, 0);
    $self->{sz_buttons}->Add($self->{b_ok}, 0, wxADJUST_MINSIZE, 0);
    $self->{sz_buttons}->Add(5, 1, 1, wxEXPAND|wxADJUST_MINSIZE, 0);
    $self->{sz_contents}->Add($self->{sz_buttons}, 0, wxEXPAND, 0);
    $self->{sz_main}->Add($self->{sz_contents}, 1, wxALL|wxEXPAND, 5);
    $self->SetSizer($self->{sz_main});
    $self->{sz_main}->Fit($self);
    $self->Layout();
    # end wxGlade
}

sub hush {
    my ($self) = @_;
    $self->{cb_remind}->IsChecked;
}

sub forced {
    my ($self) = @_;
    # No "don't remind" checkbox if the check is forced.
    $self->{sz_contents}->Hide( $self->{sz_cb} );
    $self->{sz_contents}->Layout;
}

sub OnOk {
    my ($self, $event) = @_;
    # wxGlade: EB::Wx::Shell::UpdateDialog::OnOk <event_handler>
    $self->EndModal(0);
    $event->Skip;
    # end wxGlade
}

# end of class EB::Wx::Shell::UpdateDialog

1;
