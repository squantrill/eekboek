package EB::Wx::UI::GridPanel::AmountInput;

use Wx qw(:allclasses wxDefaultPosition wxDefaultSize);
use base qw(EB::Wx::UI::AmountCtrl);
use strict;
use EB::Format;

sub new {
    my ($class, $parent, $arg) = @_;
    $class = ref($class) || $class;
    $arg = 0 unless defined $arg;
    my $self = $class->SUPER::new($parent, -1, $arg,
				  wxDefaultPosition, wxDefaultSize, 0);
    $self->{committed_value} = $arg;
    $self;
}

sub value {
    my ($self) = @_;
    amount($self->GetValue);
}

sub setvalue {
    my ($self, $value) = @_;
    $self->SetValue(amtfmt($value));
}

sub changed {
    my ($self) = @_;
    $self->value ne $self->{committed_value};
}

sub registerchangecallback {
    my ($self, $cb) = @_;
    Wx::Event::EVT_TEXT($self->GetParent, $self->GetId, $cb);
}

sub reset {
    my ($self) = @_;
    $self->setvalue($self->{committed_value});
}

sub commit {
    my ($self) = @_;
    $self->{committed_value} = $self->value;
}

1;
