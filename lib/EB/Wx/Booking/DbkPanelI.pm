# generated by wxGlade 0.4cvs on Tue Aug  2 13:48:00 2005
# To get wxPerl visit http://wxPerl.sourceforge.net/

use Wx 0.15 qw[:allclasses];
use strict;
package DbkPanelI;

use Wx qw[:everything];
use base qw(Wx::Dialog);
use strict;

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

# begin wxGlade: DbkPanelI::new

	$style = wxDEFAULT_DIALOG_STYLE|wxRESIZE_BORDER|wxTHICK_FRAME 
		unless defined $style;

	$self = $self->SUPER::new( $parent, $id, $title, $pos, $size, $style, $name );

	$self->__set_properties();
	$self->__do_layout();

# end wxGlade
	return $self;

}


sub __set_properties {
	my $self = shift;

# begin wxGlade: DbkPanelI::__set_properties

	$self->SetTitle("Typisch Inkoop Dagboek");

# end wxGlade
}

sub __do_layout {
	my $self = shift;

# begin wxGlade: DbkPanelI::__do_layout

	$self->Layout();

# end wxGlade
}

sub init {
    my ($self, $id, $desc) = @_;
    $self->SetTitle("Dagboek $desc");
}

# end of class DbkPanelI

1;

