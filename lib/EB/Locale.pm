#! perl

# Locale.pm -- EB Locale setup (core version)
# RCS Info        : $Id: Locale.pm,v 1.9 2008/02/07 12:07:14 jv Exp $
# Author          : Johan Vromans
# Created On      : Fri Sep 16 20:27:25 2005
# Last Modified By: Johan Vromans
# Last Modified On: Thu Feb  7 13:07:02 2008
# Update Count    : 96
# Status          : Unknown, Use with caution!

package main;

our $cfg;

package EB::Locale;

use strict;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.9 $ =~ /(\d+)/g;

use base qw(Exporter);

use constant COREPACKAGE => "ebcore";

our @EXPORT_OK;
our @EXPORT;

BEGIN {
    @EXPORT_OK = qw(LOCALISER _T __x __n __nx __xn);
    @EXPORT = ( @EXPORT_OK );
}

# This module supports three different gettext implementations.

use POSIX;			# for setlocale

my $gotone = 0;

unless ( $gotone ) {
    eval {
	require Locale::gettext;
	# Use outer settings.
	setlocale(LC_MESSAGES, $ENV{EB_LANG}||"");

	our $core_localiser;
	unless ( $core_localiser ) {
	    $core_localiser = Locale::gettext->domain(COREPACKAGE);
	    $core_localiser->dir($ENV{EB_LIB} . "EB/locale");
	}

	eval 'sub _T($) {
	    $core_localiser->get($_[0]);
	}';

	eval 'sub LOCALISER() { "Locale::gettext" }';

	$gotone++;
    }
}

unless ( $gotone ) {

    if ( !$cfg || $cfg->val(qw(locale unicode), 0) ) {
	require Encode;
	eval 'sub _T($) { Encode::decode("ISO-8859-1", $_[0]) };';
	binmode(STDIN,  ":utf8");
	binmode(STDOUT, ":utf8");
	binmode(STDERR, ":utf8");
    }
    else {
	eval 'sub _T($) { $_[0] };';
    }

    eval 'sub LOCALISER() { "" }';

}

# Second alternative: Locale-gettext 1.05 (on CPAN).
# Simple and light-weight.
# It only provides the straight-forward translation, so we need
# to add the utility routines __x __n __xn __nx.

=begin later

use Locale::gettext 1.05;
use POSIX;     # Needed for setlocale()

# Use outer settings.
setlocale(LC_MESSAGES, $ENV{EB_LANG}||"");

our $core_localiser;
unless ( $core_localiser ) {
    $core_localiser = Locale::gettext->domain(COREPACKAGE);
    $core_localiser->dir($ENV{EB_LIB} . "EB/locale");
}

sub _T($) {
    $core_localiser->get($_[0]);
}

sub LOCALISER() { "Locale::gettext" }

=cut

# Variable expansion. See GNU gettext for details.
sub __expand($%) {
    my ($t, %args) = @_;
    my $re = join('|', map { quotemeta($_) } keys(%args));
    $t =~ s/\{($re)\}/defined($args{$1}) ? $args{$1} : "{$1}"/ge;
    $t;
}

# Translation w/ variables.
sub __x($@) {
    my ($t, %vars) = @_;
    __expand(_T($t), %vars);
}

# Translation w/ singular/plural handling.
sub __n($$$) {
    my ($sing, $plur, $n) = @_;
    _T($n == 1 ? $sing : $plur);
}

# Translation w/ singular/plural handling and variables.
sub __nx($$$@) {
    my ($sing, $plur, $n, %vars) = @_;
    __expand(__n($sing, $plur, $n), %vars);
}

# Make __xn a synonym for __nx.
*__xn = \&__nx;

=begin alternative

# Third alternative: libintl-perl (GNU gettext) (on CPAN).
#

# This implementation provides a smart hash binding as well as object
# references.
# It also provides the utility routines __x __n __xn __nx and more.

use Locale::TextDomain(COREPACKAGE, $ENV{EB_LIB} . "EB/locale");

sub _T($) { $__->{$_[0]} }

sub LOCALISER() { "Locale::TextDomain" }

=cut

# Perl magic.
# *_=\&_T;

# More Perl magic.

1;
