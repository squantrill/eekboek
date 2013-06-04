#! perl

use strict;
use warnings;

package EB::Tools::UpdateCheck;

use EekBoek;

use constant STATUS_URL => 'http://www.eekboek.nl/status';

sub check {
    # Create a User Agent.
    use LWP::UserAgent;
    my $ua = LWP::UserAgent->new;
    $ua->timeout(2);
    $ua->agent( "$EekBoek::PACKAGE/"
		. ( $::app ? "Wx" : "" )
		. "UpdateCheck_$EekBoek::VERSION" );
    $ua->env_proxy;

    # The return object-to-be.
    my $o = {};

    # Get info.
    my $response = $ua->get(STATUS_URL);
    return unless $response->is_success;

    # Extract known fields.
    my $t = $response->decoded_content;
    for ( qw( current reldate relnotes note ) ) {
	$o->{$_} = $1 if $t =~ m/^$_:\s+(.*)/m;
    }

    # Make object and return.
    bless $o, __PACKAGE__;
}

sub version_compare {
    my ( $c, $t ) = @_;
    my ( $t1, $t2, $t3 ) = $t =~ /^(\d+)\.(\d+)\.(\d+)/;
    my ( $c1, $c2, $c3 ) = $c =~ /^(\d+)\.(\d+)\.(\d+)/;
    $c1 <=> $t1 || $c2 <=> $t2 || $c3 <=> $t3;
}

unless (caller) {
    use Data::Dumper;
    warn Dumper( check() );
}


1;
