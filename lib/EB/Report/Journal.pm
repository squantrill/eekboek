#!/usr/bin/perl -w
my $RCS_Id = '$Id: Journal.pm,v 1.5 2005/07/26 14:03:22 jv Exp $ ';

# Author          : Johan Vromans
# Created On      : Sat Jun 11 13:44:43 2005
# Last Modified By: Johan Vromans
# Last Modified On: Tue Jul 26 16:00:56 2005
# Update Count    : 117
# Status          : Unknown, Use with caution!

################ Common stuff ################

package EB::Journal::Text;

use strict;
use warnings;

use EB::Globals;
use EB::Finance;
use EB::DB;

sub new {
    bless {};
}

use locale;

my $repfmt = "%-10s  %3s  %-4s  %-30.30s  %5s  %9s  %9s  %-30.30s  %s\n";

sub journal {
    my ($self, $nr) = @_;

    my $sth;
    if ( $nr ) {
	if ( $nr =~ /^([[:alpha:]].+):(\d+)$/ ) {
	    my $dbk = $::dbh->lookup($1, qw(Dagboeken dbk_desc dbk_id ilike));
	    unless ( $dbk ) {
		warn("?Onbekend dagboek: $1\n");
		return;
	    }
	    $sth = $::dbh->sql_exec("SELECT jnl_date, jnl_dbk_id, jnl_bsk_id, bsk_nr, jnl_bsr_seq, ".
				    "jnl_acc_id, jnl_amount, jnl_desc, jnl_rel".
				    " FROM Journal, Boekstukken, Dagboeken".
				    " WHERE bsk_nr = ?".
				    " AND dbk_id = ?".
				    " AND jnl_bsk_id = bsk_id".
				    " AND jnl_dbk_id = dbk_id".
				    " ORDER BY jnl_date, jnl_dbk_id, jnl_bsk_id, jnl_bsr_seq",
				    $2, $dbk);
	}
	elsif ( $nr =~ /^([[:alpha:]].+)$/ ) {
	    my $dbk = $::dbh->lookup($1, qw(Dagboeken dbk_desc dbk_id ilike));
	    unless ( $dbk ) {
		warn("?Onbekend dagboek: $1\n");
		return;
	    }
	    $sth = $::dbh->sql_exec("SELECT jnl_date, jnl_dbk_id, jnl_bsk_id, bsk_nr, jnl_bsr_seq, ".
				    "jnl_acc_id, jnl_amount, jnl_desc, jnl_rel".
				    " FROM Journal, Boekstukken, Dagboeken".
				    " WHERE dbk_id = ?".
				    " AND jnl_bsk_id = bsk_id".
				    " AND jnl_dbk_id = dbk_id".
				    " ORDER BY jnl_date, jnl_dbk_id, jnl_bsk_id, jnl_bsr_seq",
				    $dbk);
	}
	else {
	    $sth = $::dbh->sql_exec("SELECT jnl_date, jnl_dbk_id, jnl_bsk_id, bsk_nr, jnl_bsr_seq, ".
				    "jnl_acc_id, jnl_amount, jnl_desc, jnl_rel".
				    " FROM Journal, Boekstukken".
				    " WHERE jnl_bsk_id = ?".
				    " AND jnl_bsk_id = bsk_id".
				    " ORDER BY jnl_date, jnl_dbk_id, jnl_bsk_id, jnl_bsr_seq",
				    $nr);
	}
    }
    else {
	$sth = $::dbh->sql_exec("SELECT jnl_date, jnl_dbk_id, jnl_bsk_id, bsk_nr, jnl_bsr_seq, ".
				"jnl_acc_id, jnl_amount, jnl_desc, jnl_rel".
				" FROM Journal, Boekstukken".
				" WHERE jnl_bsk_id = bsk_id".
				" ORDER BY jnl_date, jnl_dbk_id, jnl_bsk_id, jnl_bsr_seq");
    }
    my $rr;
    my $nl = 0;
    my $totd = my $totc = 0;

    while ( $rr = $sth->fetchrow_arrayref ) {
	my ($jnl_date, $jnl_dbk_id, $jnl_bsk_id, $bsk_nr, $jnl_bsr_seq, $jnl_acc_id,
	    $jnl_amount, $jnl_desc, $jnl_rel) = @$rr;

	if ( $jnl_bsr_seq == 0 ) {
	    printf($repfmt,
		   qw(Datum Id Nr Dag/Grootboek Rek Debet Credit Boekstuk/regel Relatie)) unless $nl;
	    print("\n") if $nl++;
	    $self->_repline($jnl_date, $jnl_bsk_id, $bsk_nr, _dbk_desc($jnl_dbk_id), '',
			    '', '', $jnl_desc);
	    next;
	}

	$totd += $jnl_amount if $jnl_amount > 0;
	$totc -= $jnl_amount if $jnl_amount < 0;
	$self->_repline($jnl_date, '', '', "  "._acc_desc($jnl_acc_id),
			$jnl_acc_id, numdebcrd($jnl_amount), "  ".$jnl_desc, $jnl_rel);
    }
    $self->_repline('', '', '', 'Totaal', '', $totd, $totc);
}

sub _repline {
    my ($self, $date, $bsk, $nr, $loc, $acc, $deb, $crd, $desc, $rel) = (@_, ('') x 7);
    for ( $deb, $crd ) {
	$_ = $_ ? numfmt($_) : '';
    }
    printf($repfmt,
	   $date, $bsk, $nr, $loc, $acc, $deb, $crd, $desc, $rel || '');
}

my %dbk_desc;
sub _dbk_desc {
    $dbk_desc{$_[0]} ||= $::dbh->lookup($_[0],
				      qw(Dagboeken dbk_id dbk_desc =));
}

my %acc_desc;
sub _acc_desc {
    return '' unless $_[0];
    $acc_desc{$_[0]} ||= $::dbh->lookup($_[0],
				      qw(Accounts acc_id acc_desc =));
}

1;
