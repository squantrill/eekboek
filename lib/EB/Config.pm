#! perl --			-*- coding: utf-8 -*-

use utf8;

# Config.pm -- Configuration files.
# RCS Info        : $Id: Config.pm,v 1.20 2009/10/16 18:24:16 jv Exp $
# Author          : Johan Vromans
# Created On      : Fri Jan 20 17:57:13 2006
# Last Modified By: Johan Vromans
# Last Modified On: Fri Oct 16 20:23:40 2009
# Update Count    : 134
# Status          : Unknown, Use with caution!

package main;

our $cfg;
our $dbh;

package EB::Config;

use strict;
use warnings;
use Carp;

our $VERSION = sprintf "%d.%03d", q$Revision: 1.20 $ =~ /(\d+)/g;

#use EB::Config::IniFiles;
use File::Spec;

sub init_config {
    my ($app) = @_;

    $app = lc($app);

    # Pre-parse @ARGV for "-f configfile".
    my $extraconf;
    my $skipconfig = 0;
    my $i = 0;
    while ( $i < @ARGV ) {
	if ( $ARGV[$i] eq "-f" || $ARGV[$i] eq "-config" || $ARGV[$i] eq "--config" ) {
	    if ( $i+1 < @ARGV ) {
		$extraconf = $ARGV[$i+1];
		splice(@ARGV, $i, 2);
		last;
	    }
	}
	elsif ( $ARGV[$i] =~ /^-f(.+)/ || $ARGV[$i] =~ /--?config=(.+)/ ) {
	    $extraconf = $1;
	    splice(@ARGV, $i, 1);
	    last;
	}
	elsif ( $ARGV[$i] eq "-X" || $ARGV[$i] =~ /^--?no-?config$/ ) {
	    $skipconfig++;
	    splice(@ARGV, $i, 1);
	    next;
	}
	$i++;
    }

    # Resolve extraconf to a file name. It must exist.
    if ( $extraconf ) {
	if ( -d $extraconf ) {
	    my $f = File::Spec->catfile($extraconf, "$app.conf");
	    if ( -e $f ) {
		$extraconf = $f;
	    }
	    else {
		$extraconf = File::Spec->catfile($extraconf, ".$app.conf");
	    }
	}
	die("$extraconf: $!\n") unless -f $extraconf;
    }

    # Build the list of config files.
    my @cfgs;
    if ( !$skipconfig ) {
	@cfgs = ( "/etc/$app/$app.conf",
		  $ENV{HOME}."/.$app/$app.conf" );
	push(@cfgs, ".$app.conf") unless $extraconf;
    }
    push(@cfgs, $extraconf) if $extraconf;

    # Load configs.
    my $cfg;
    for my $file ( @cfgs ) {
	next unless -s $file;
	$cfg = EB::Config::Data->new($file);

    }
    # Make sure we have an object, even if no config files.
    $cfg ||= EB::Config::Data->new;

    $i = 0;
    while ( $i < @ARGV ) {
	if ( $ARGV[$i] eq "-D" &&
	     $i+1 < @ARGV && $ARGV[$i+1] =~ /^(\w+(?:::\w+)*)::?(\w+)=(.*)/ ) {
	    $cfg->newval($1, $2, $3);
	    splice(@ARGV, $i, 2);
	    next;
	}
	elsif ( $ARGV[$i] =~ /^--define=(\w+(?:::\w+)*)::?(\w+)=(.*)/ ) {
	    $cfg->newval($1, $2, $3);
	    splice(@ARGV, $i, 1);
	    next;
	}
	$i++;
    }

    $ENV{EB_LANG} = $cfg->val('locale','lang',
			      $ENV{EB_LANG}||$ENV{LANG}||
			      ($^O =~ /^(ms)?win/i ? "nl_NL.utf8" : "nl_NL"));

    $cfg->_plug(qw(locale       lang         EB_LANG));

    $cfg->_plug(qw(database     name         EB_DB_NAME));

    if ( my $db = $cfg->val(qw(database name), undef) ) {
	$db =~ s/^eekboek_//;
	$cfg->newval(qw(database     name), $db);
	$cfg->newval(qw(database fullname), "eekboek_".$db);
	$ENV{EB_DB_NAME} = $db;
    }

    $cfg->_plug(qw(database     host         EB_DB_HOST));
    $cfg->_plug(qw(database     port         EB_DB_PORT));
    $cfg->_plug(qw(database     user         EB_DB_USER));
    $cfg->_plug(qw(database     password     EB_DB_PASSWORD));

    $cfg->_plug(qw(csv          separator    EB_CSV_SEPARATOR));

    $cfg->_plug(qw(internal     now          EB_SQL_NOW));

    $cfg->_plug("internal sql", qw(trace     EB_SQL_TRACE));
    $cfg->_plug("internal sql", qw(prepstats EB_SQL_PREP_STATS));
    $cfg->_plug("internal sql", qw(replayout EB_SQL_REP_LAYOUT));

    if ( $cfg->val(__PACKAGE__, "showfiles", 0) ) {
	warn("Config files:\n  ",
	     $cfg->{imported}
	     ? join("\n  ", @{$cfg->{imported}}, $cfg->{cf})
	     : $cfg->{cf}, "\n");
    }

    return $cfg;
}

sub import {
    my ($self, $app) = @_;
    $cfg = init_config($app);
}

package EB::Config::Data;

# Very simple inifile handler (read-only).

sub _key {
    my ($section, $parameter) = @_;
    $section.'::'.$parameter;
}

sub val {
    my ($self, $section, $parameter, $default) = @_;
    my $res;
    $res = $self->{_data_}->{ _key($section, $parameter) };
     defined $res ? $res : "<undef>", "\n");
    $res = $default unless defined $res;
    Carp::cluck("=> missing config: \"" . _key($section, $parameter) . "\"\n")
      unless defined $res || @_ > 3;
    $res;
}

sub newval {
    my ($self, $section, $parameter, $value) = @_;
    $self->{_data_}->{ _key($section, $parameter) } = $value;
}

sub setval {
    my ($self, $section, $parameter, $value) = @_;
    my $key = _key( $section, $parameter );
    Carp::cluck("=> missing config: \"$key\"\n")
      unless exists $self->{_data_}->{ $key };
    $self->{_data_}->{ $key } = $value;
}

sub _plug {
    my ($self, $section, $parameter, $env) = @_;
    $self->newval($section, $parameter, $ENV{$env})
      if $ENV{$env} && !$self->val($section, $parameter, undef);
}

sub new {
    my ($package, $file) = @_;
    my $self = bless {}, $package;
    $self->{_data_} = {};

    return $self unless $file;

    open( my $fd, "<:encoding(utf-8)", $file )
      or Carp::croak("Error opening config $file: $!\n");

    my $section = "global";
    my $fail;
    while ( <$fd> ) {
	chomp;
	next unless /\S/;
	next if /^[#;]/;
	if ( /^\s*\[\s*(.*?)\s*\]\s*$/ ) {
	    $section = lc $1;
	    next;
	}
	if ( /^\s*(.*?)\s*=\s*(.*?)\s*$/ ) {
	    $self->{_data_}->{ _key($section, lc($1)) } = $2;
	    next;
	}
	Carp::cluck("Error in config $file, line $.:\n$_\n");
	$fail++;
    }
    Carp::croak("Error processing config $file, aborted\n")
	if $fail;

    $self;
}

1;
