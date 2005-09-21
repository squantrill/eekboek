# Locale.pm -- EB Locale setup (core version)
# RCS Info        : $Id: Locale.pm,v 1.1 2005/09/18 21:08:13 jv Exp $
# Author          : Johan Vromans
# Created On      : Fri Sep 16 20:27:25 2005
# Last Modified By: Johan Vromans
# Last Modified On: Sun Sep 18 16:20:36 2005
# Update Count    : 55
# Status          : Unknown, Use with caution!

package EB::Locale;

use base qw(Exporter);
use strict;

use constant COREPACKAGE => "ebcore";

our @EXPORT_OK;
our @EXPORT;

BEGIN {
    @EXPORT_OK = qw(_T __x __n __nx __xn);
    @EXPORT = ( @EXPORT_OK );
}

# This module supports two different gettext implementations.

# First alternative: Locale-gettext 1.05 (on CPAN).
# Simple and leight-weight.
# It only provides the straight-forward translation, so we need
# to add the utility routines __x __n __xn __nx.

use Locale::gettext 1.05;
use POSIX;     # Needed for setlocale()

# Use outer settings.
setlocale(LC_MESSAGES, "");

our $core_localiser;
unless ( $core_localiser ) {
    $core_localiser = Locale::gettext->domain(COREPACKAGE);
    $core_localiser->dir($ENV{EB_LIB} . "EB/locale");
}

sub _T($) {
    $core_localiser->get($_[0]);
}

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

=cut

=begin alternative

# Second alternative: libintl-perl (GNU gettext) (on CPAN).
#

# This implementation provides a smart hash binding as well as object
# references.
# It also provides the utility routines __x __n __xn __nx and more.

use Locale::TextDomain(COREPACKAGE, $ENV{EB_LIB} . "EB/locale");

sub _T($) { $__->{$_[0]} }

=cut

# Perl magic.
# *_=\&_T;

# More Perl magic.
1;