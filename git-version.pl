#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;

# Tag revisions like this:
# $ git tag -a -m "Version 2.01.03" R02_01_03 HEAD

my $vfile = "lib/EB/Version.pm";
my $DEFAULT_VERSION = "UNKNOWN";
my $devnull = File::Spec->devnull;

# First see if there is a version file (included in release tarballs),
# then try git-describe, then default.

my $version = $DEFAULT_VERSION;

# Parse the existing VERSION-FILE.
my $vprev = "";
if ( open( my $vf, '<', $vfile ) ) {
    local $/;
    $vprev = scalar(<$vf>);
    $vprev = $1 if $vprev =~ /VERSION\s*=\s*"([^"]+)"/ms;
}

if ( -d ".git" || -f ".git" ) {
    $version = `git describe --tags --abbrev=6 HEAD 2>$devnull` || "";
    if ( $version =~ /^R0?(\d+)_(\d+)_(\d+)(.*)/ ) {
	if ( $3 % 2 == 0 ) {
	    $version = "$1.$2.$3";
	}
	else {
	    $version = "$1.$2.$3$4";
	    if ( `git diff-index --name-only HEAD --` ) {
		$version .= "-mod";
	    }
	}
    }
    else {
	$version = $DEFAULT_VERSION;
    }
}
else {
    $version = $vprev;
}

# If version has changed, update VERSION-FILE.
if ( $version ne $vprev ) {
    open( my $vf, '>', $vfile );
    print { $vf } ( "# This file is generated. Do not edit!\n",
		    "package EB::Version;\n",
		    "our \$VERSION = \"$version\";\n");
    close($vf) or die;
    # Show the version to the user via STDERR.
    warn("new version: $version\n") if -t STDERR;
}
else {
    # Show the version to the user via STDERR.
    warn("version: $version\n") if -t STDERR;
}
