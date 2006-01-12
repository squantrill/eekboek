# RCS Info        : $Id: GenBase.pm,v 1.15 2006/01/12 21:18:08 jv Exp $
# Author          : Johan Vromans
# Created On      : Sat Oct  8 16:40:43 2005
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jan 12 21:51:00 2006
# Update Count    : 101
# Status          : Unknown, Use with caution!

package main;

our $dbh;

package EB::Report::GenBase;

use strict;
use EB;
use IO::File;

sub new {
    my ($class, $opts) = @_;
    $class = ref($class) || $class;
    my $self = { %$opts };
    bless $self => $class;
}

# API.
sub _oops   { warn("?Package ".ref($_[0])." did not implement '$_[1]' method\n") }
sub start   { shift->_oops('start')   }
sub outline { shift->_oops('outline') }
sub finish  { shift->_oops('finish')  }

# Class methods

sub backend {
    my (undef, $self, $opts) = @_;

    my %extmap = ( txt => "text", htm => "html" );

    my $gen;

    # Short options, like --html.
    for ( qw(html csv text) ) {
	$gen = $_ if $opts->{$_};
    }

    # Override by explicit --gen-XXX option(s).
    foreach ( keys(%$opts) ) {
	next unless /^gen-(.*)$/;
	$gen = $1;
    }

    # Infer from filename extension.
    my $t;
    if ( !defined($gen) && ($t = $opts->{output}) && $t =~ /\.([^.]+)$/ ) {
	my $ext = lc($1);
	$ext = $extmap{$ext} || $ext;
	$gen = $ext;
    }

    # Fallback to text.
    $gen ||= "text";

    # Build class and package name.
    my $class = (ref($self)||$self) . "::" . ucfirst($gen);
    my $pkg = $class;
    $pkg =~ s;::;/;g;;
    $pkg .= ".pm";

    # Try to load backend. Gives user the opportunity to override.
    eval { require $pkg };
    if ( ! _loaded($class) ) {
	die("?".__x("Onbekend uitvoertype: {gen}\n{err}",
		    gen => $gen, err => $@)."\n");
    }
    my $be = $class->new($opts);

    # Handle output redirection.
    if ( $opts->{output} && $opts->{output} ne '-' ) {
	$be->{fh} = IO::File->new($opts->{output}, "w")
	  or die("?".__x("Fout tijdens aanmaken {file}: {err}",
			 file => $opts->{output}, err => $!)."\n");
    }
    else {
	$be->{fh} = IO::File->new_from_fd(fileno(STDOUT), "w");
    }

    # Handle pagesize.
    $be->{fh}->format_lines_per_page($be->{page} = defined($opts->{page}) ? $opts->{page} : 999999);

    # Get real (or fake) current date, and adjust periode end if needed.
    $be->{now} = iso8601date();
    $be->{now} = $ENV{EB_SQL_NOW} if $ENV{EB_SQL_NOW} && $be->{now} gt $ENV{EB_SQL_NOW};

    # Date/Per.
    if ( $opts->{per} ) {
	die(_T("--per sluit --periode uit")."\n") if $opts->{periode};
	die(_T("--per sluit --boekjaar uit")."\n") if defined $opts->{boekjaar};
	$be->{per_begin} = $dbh->adm("begin");
	$be->{per_end} = $opts->{per};
	$be->{periode} = [$be->{per_begin},$be->{per_end}];
	$be->{periodex} = 1;
    }
    elsif ( $opts->{periode} ) {
	die(_T("--periode sluit --boekjaar uit")."\n") if defined $opts->{boekjaar};
	$be->{periode} = $opts->{periode};
	$be->{per_begin} = $opts->{periode}->[0];
	$be->{per_end} = $opts->{periode}->[1];
	$be->{periodex} = 2;
    }
    elsif ( defined($opts->{boekjaar}) || defined($opts->{d_boekjaar}) ) {
	my $bky = $opts->{boekjaar};
	$bky = $opts->{d_boekjaar} unless defined $bky;
	my $rr = $dbh->do("SELECT bky_begin, bky_end".
			  " FROM Boekjaren".
			  " WHERE bky_code = ?", $bky);
	die("?",__x("Onbekend boekjaar: {bky}", bky => $bky)."\n"), return unless $rr;
	my ($begin, $end) = @$rr;
	$be->{periode} = [$begin, $end];
	$be->{per_begin} = $begin;
	$be->{per_end} = $end;
	$be->{periodex} = 3;
	$be->{boekjaar} = $bky;
    }
    else {
	$be->{periode} = [ $dbh->adm("begin"),
			   $dbh->adm("end") ];
	$be->{per_begin} = $opts->{periode}->[0];
	$be->{per_end} = $opts->{periode}->[1];
	$be->{periodex} = 0;
    }

    if ( $be->{per_end} gt $be->{now} ) {
	warn("!".__x("Datum {per} valt na de huidige datum {now}",
		     per => $be->{per_end}, now => $be->{now})."\n")
	  if 0;
	$be->{periode}->[1] = $be->{per_end} = $be->{now};
    }

    # Sanity.
    my $opendate = $dbh->do("SELECT min(bky_begin) FROM boekjaren WHERE NOT bky_code = ?",
			    BKY_PREVIOUS)->[0];

    if ( $be->{per_begin} gt $be->{now} ) {
	die("?".__x("Periode begint {from}, dit is na de huidige datum {now}",
		    from => $be->{per_begin},
		    now => $be->{now})."\n");
    }
    if ( $be->{per_begin} lt $opendate ) {
	die("?".__x("Datum {per} valt v��r het begin van de administratie {begin}",
		    per => $be->{per_begin}, begin => $opendate)."\n");
    }
    if ( $be->{per_end} lt $opendate ) {
	die("?".__x("Datum {per} valt v��r het begin van de administratie {begin}",
		    per => $be->{per_end}, begin => $opendate)."\n");
    }

    $be->{_style} = $opts->{style} if $opts->{style};

    # Return instance.
    $be;
}

my %bec;

sub backend_options {
    my (undef, $self, $opts) = @_;

    my $package = ref($self) || $self;
    my $pkg = $package;
    $pkg =~ s;::;/;g;;
    return @{$bec{$pkg}} if $bec{$pkg};

    # Some standard backends may be included in the coding ...
    my %be;
    foreach my $std ( qw(text html csv) ) {
	$be{$std} = 1 if _loaded($package . "::" . ucfirst($std));
    }
    my @opts = qw(output=s page=i);

    # Find files.
    foreach my $lib ( @INC ) {
	my @files = glob("$lib/$pkg/*.pm");
	next unless @files;
	# warn("=> be_opt: found ", scalar(@files), " files in $lib/$pkg\n");
	foreach ( @files ) {
	    next unless m;/([^/]+)\.pm$;;
	    # Actually, we should check whether the class implements the
	    # GenBase API, but we can't do that without preloading all
	    # backends.
	    $be{lc($1)}++;
	}
    }

    # Short --XXX for known backends.
    foreach ( qw(html csv text) ) {
	push(@opts, $_) if $be{$_};
    }
    push(@opts, "style=s") if $be{html};

    # Explicit --gen-XXX for all backends.
    push(@opts, map { +"gen-$_"} keys %be);
    # Cache.
    $bec{$pkg} = [@opts];

    @opts;			# better be list context
}

# Helper.

sub _loaded {
    my $class = shift;
    no strict "refs";
    %{$class . "::"} ? 1 : 0;
}
1;
