# generated by wxGlade 0.4cvs on Wed Aug  3 22:49:38 2005
# To get wxPerl visit http://wxPerl.sourceforge.net/

package main;

our $config;

use Wx 0.15 qw[:allclasses];
use strict;
package EB::Wx::Report::Journaal;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use strict;
use EB;

# begin wxGlade: ::dependencies
# end wxGlade

sub new {
	my( $self, $parent, $id, $title, $pos, $size, $style, $name ) = @_;
	$parent = undef              unless defined $parent;
	$id     = -1                 unless defined $id;
	$title  = ""                 unless defined $title;
	$pos    = wxDefaultPosition  unless defined $pos;
	$size   = wxDefaultSize      unless defined $size;
	$name   = ""                 unless defined $name;

# begin wxGlade: EB::Wx::Report::Journaal::new

	$style = wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER|wxTHICK_FRAME 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );
	$self->{b_refresh} = Wx::Button->new($self, wxID_REFRESH, "");
	$self->{b_props} = Wx::Button->new($self, wxID_PROPERTIES, "");
	$self->{l_detail} = Wx::StaticText->new($self, -1, _T("Detail:"), wxDefaultPosition, wxDefaultSize, );
	$self->{bd_less} = Wx::BitmapButton->new($self, -1, Wx::Bitmap->new("edit_remove.png", wxBITMAP_TYPE_ANY));
	$self->{bd_more} = Wx::BitmapButton->new($self, -1, Wx::Bitmap->new("edit_add.png", wxBITMAP_TYPE_ANY));
	$self->{b_print} = Wx::Button->new($self, wxID_PRINT, "");
	$self->{b_close} = Wx::Button->new($self, wxID_CLOSE, "");
	$self->{w_report} = Wx::HtmlWindow->new($self, -1, wxDefaultPosition, wxDefaultSize, );

	$self->__set_properties();
	$self->__do_layout();

	Wx::Event::EVT_BUTTON($self, wxID_REFRESH, \&OnRefresh);
	Wx::Event::EVT_BUTTON($self, wxID_PROPERTIES, \&OnProps);
	Wx::Event::EVT_BUTTON($self, $self->{bd_less}->GetId, \&OnLess);
	Wx::Event::EVT_BUTTON($self, $self->{bd_more}->GetId, \&OnMore);
	Wx::Event::EVT_BUTTON($self, wxID_PRINT, \&OnPrint);
	Wx::Event::EVT_BUTTON($self, wxID_CLOSE, \&OnClose);

# end wxGlade

	$self->{_PRINTER} =  Wx::HtmlEasyPrinting->new('Print');

	return $self;

}


sub __set_properties {
	my $self = shift;

# begin wxGlade: EB::Wx::Report::Journaal::__set_properties

	$self->SetTitle(_T("Journaal"));
	$self->{b_refresh}->SetToolTipString(_T("Bijwerken naar laatste gegevens"));
	$self->{b_props}->SetToolTipString(_T("Instellingsgegevens"));
	$self->{bd_less}->SetToolTipString(_T("Minder uitgebreid"));
	$self->{bd_less}->SetSize($self->{bd_less}->GetBestSize());
	$self->{bd_more}->SetToolTipString(_T("Meer uitgebreid"));
	$self->{bd_more}->SetSize($self->{bd_more}->GetBestSize());
	$self->{b_print}->SetToolTipString(_T("Overzicht afdrukken"));
	$self->{b_close}->SetToolTipString(_T("Venster sluiten"));

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: EB::Wx::Report::Journaal::__do_layout

	$self->{sizer_1} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sizer_2} = Wx::BoxSizer->new(wxVERTICAL);
	$self->{sizer_3} = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{sizer_3}->Add($self->{b_refresh}, 0, wxLEFT|wxTOP|wxEXPAND|wxADJUST_MINSIZE, 5);
	$self->{sizer_3}->Add($self->{b_props}, 0, wxLEFT|wxTOP|wxEXPAND|wxADJUST_MINSIZE, 5);
	$self->{sizer_3}->Add(5, 1, 1, wxADJUST_MINSIZE, 0);
	$self->{sizer_3}->Add($self->{l_detail}, 0, wxLEFT|wxTOP|wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 5);
	$self->{sizer_3}->Add($self->{bd_less}, 0, wxTOP|wxEXPAND|wxALIGN_CENTER_VERTICAL|wxADJUST_MINSIZE, 5);
	$self->{sizer_3}->Add($self->{bd_more}, 0, wxTOP|wxEXPAND|wxADJUST_MINSIZE, 5);
	$self->{sizer_3}->Add(5, 1, 1, wxEXPAND|wxADJUST_MINSIZE, 0);
	$self->{sizer_3}->Add($self->{b_print}, 0, wxRIGHT|wxTOP|wxADJUST_MINSIZE, 5);
	$self->{sizer_3}->Add($self->{b_close}, 0, wxRIGHT|wxTOP|wxEXPAND|wxADJUST_MINSIZE, 5);
	$self->{sizer_2}->Add($self->{sizer_3}, 0, wxBOTTOM|wxEXPAND, 5);
	$self->{sizer_2}->Add($self->{w_report}, 1, wxEXPAND, 0);
	$self->{sizer_1}->Add($self->{sizer_2}, 1, wxEXPAND, 5);
	$self->SetSizer($self->{sizer_1});
	$self->{sizer_1}->Fit($self);
	$self->Layout();

# end wxGlade
}

sub init {
    my ($self, $me) = @_;
    $self->{mew} = "r${me}w";
    $self->{bd_more}->Enable(0);
    $self->{bd_less}->Enable(1);
    $self->refresh;
}

sub refresh {
    my ($self) = @_;
    my $output = "<h1>Output</h1>";
    $self->html->SetPage($output);
    $self->{_HTMLTEXT} = $output;
}

sub html     { $_[0]->{w_report}  }
sub htmltext { $_[0]->{_HTMLTEXT} }
sub printer  { $_[0]->{_PRINTER}  }

# wxGlade: EB::Wx::Report::Journaal::OnRefresh <event_handler>
sub OnRefresh {
    my ($self, $event) = @_;
    $self->refresh;
}

# wxGlade: EB::Wx::Report::Journaal::OnProps <event_handler>
sub OnProps {
    my ($self, $event) = @_;

    warn "Event handler (OnProps) not implemented";
    $event->Skip;
}

# wxGlade: EB::Wx::Report::Journaal::OnMore <event_handler>
sub OnMore {
    my ($self, $event) = @_;

    if ( $self->{detail} < 2 ) {
	$self->{detail}++;
	$self->refresh;
    }
    $self->{bd_more}->Enable($self->{detail} < 2);
    $self->{bd_less}->Enable($self->{detail} >= 0);
}

# wxGlade: EB::Wx::Report::Journaal::OnLess <event_handler>
sub OnLess {
    my ($self, $event) = @_;

    if ( $self->{detail} >= 0 ) {
	$self->{detail}--;
	$self->refresh;
    }
    $self->{bd_more}->Enable($self->{detail} < 2);
    $self->{bd_less}->Enable($self->{detail} >= 0);
}

# wxGlade: EB::Wx::Report::Journaal::OnPrint <event_handler>
sub OnPrint {
    my ($self, $event) = @_;
    $self->printer->SetFooter(_T("Blad:").' @PAGENUM@');
    $self->printer->PrintText($self->htmltext);
}

# wxGlade: EB::Wx::Report::Journaal::OnClose <event_handler>
sub OnClose {
    my ($self, $event) = @_;
    @{$config->get($self->{mew})}{qw(xpos ypos xwidth ywidth)} = ($self->GetPositionXY, $self->GetSizeWH);
    $self->Show(0);
}

# end of class EB::Wx::Report::Journaal

################ Report handler for Balans/Report ################

package EB::Wx::Report::Journaal::WxHtml;

use EB;
use base qw(EB::Report::Reporter::WxHtml);

sub style {
    my ($self, $row, $cell) = @_;

    my $stylesheet = {
	d2    => {
	    desc   => { indent => 2      },
	},
	h1    => {
	    _style => { colour => 'red',
			size   => '+2',
		      }
	},
	h2    => {
	    _style => { colour => 'red'  },
	    desc   => { indent => 1,},
	},
	t1    => {
	    _style => { colour => 'blue',
			size   => '+1',
		      }
	},
	t2    => {
	    _style => { colour => 'blue' },
	    desc   => { indent => 1      },
	},
	v     => {
	    _style => { colour => 'red',
			size   => '+2',
		      }
	},
	grand => {
	    _style => { colour => 'blue' }
	},
    };

    $cell = "_style" unless defined($cell);
    return $stylesheet->{$row}->{$cell};
}

1;

