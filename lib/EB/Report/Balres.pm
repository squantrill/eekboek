#!/usr/bin/perl -w
my $RCS_Id = '$Id: Balres.pm,v 1.2 2005/07/14 19:39:42 jv Exp $ ';

package EB::Report::Balres;

# Author          : Johan Vromans
# Created On      : Sat Jun 11 13:44:43 2005
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jul 14 15:47:09 2005
# Update Count    : 143
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;

################ The Process ################

use EB::Globals;
use EB::DB;
use EB::Finance;
use EB::Report::Text;

use locale;

my $fmt = "%-6s  %-40.40s  %9s  %9s\n";

################ Subroutines ################

sub new {
    return bless {};
}

sub balans {
    my ($self, $opts) = @_;
    $opts->{balans} = 1;
    $self->perform($opts);
}

sub result {
    my ($self, $opts) = @_;
    $opts->{balans} = 0;
    $self->perform($opts);
}

sub perform {
    my ($self, $opts) = @_;

    my $balans = $opts->{balans};
    my $detail = $opts->{detail};
    $detail = -1 unless defined $detail;

    my $dtot = 0;
    my $ctot = 0;
    my $rep = new EB::Report::Text;

    my $rr = $::dbh->do("SELECT adm_begin FROM Metadata");
    my $date = $rr->[0];
    $rr = $::dbh->do("SELECT now()");
    $rep->addline('H', '',
		  ($balans ? "Balans" : "Verlies/Winst") .
		  " -- Periode $date - " .
		  substr($rr->[0],0,10));

    my $sth;

    # Need this until we've got the acc_balance column right...
    $sth = $::dbh->sql_exec("SELECT jnl_acc_id,acc_balance,acc_ibalance,SUM(jnl_amount)".
			    " FROM journal,accounts".
			    " WHERE acc_id = jnl_acc_id".
			    " GROUP BY jnl_acc_id,acc_balance,acc_ibalance");

    while ( $rr = $sth->fetchrow_arrayref ) {
	my ($acc_id, $balance,$ibalance, $sum) = @$rr;
	$sum += $ibalance;
	next if $balance == $sum;
	warn("!Grootboekrekening $acc_id, totaal " .
	     numfmt($balance) . ", moet zijn " . numfmt($sum) . ", aangepast\n");
	$::dbh->sql_exec("UPDATE Accounts".
			 " SET acc_balance = ?".
			 " WHERE acc_id = ?",
			 $sum, $acc_id)->finish;
    }
    $::dbh->commit;

    if ( $detail >= 0 ) {
	my @vd;
	my @hvd;
	$sth = $::dbh->sql_exec("SELECT vdi_id, vdi_desc".
			      " FROM Verdichtingen".
			      " WHERE".($balans ? "" : " NOT")." vdi_balres".
			      " AND vdi_struct IS NULL".
			      " ORDER BY vdi_id");
	while ( $rr = $sth->fetchrow_arrayref ) {
	    $hvd[$rr->[0]] = [ @$rr, []];
	}
	$sth->finish;
	@vd = @hvd;
	$sth = $::dbh->sql_exec("SELECT vdi_id, vdi_desc, vdi_struct".
			      " FROM Verdichtingen".
			      " WHERE".($balans ? "" : " NOT")." vdi_balres".
			      " AND vdi_struct IS NOT NULL".
			      " ORDER BY vdi_id");
	while ( $rr = $sth->fetchrow_arrayref ) {
	    push(@{$hvd[$rr->[2]]->[2]}, [@$rr]);
	    @vd[$rr->[0]] = [@$rr];
	}
	$sth->finish;

	foreach my $hvd ( @hvd ) {
	    next unless defined $hvd;
	    my $did_hvd = 0;
	    my $dstot = 0;
	    my $cstot = 0;
	    foreach my $vd ( @{$hvd->[2]} ) {
		my $did_vd = 0;
		$sth = $::dbh->sql_exec("SELECT acc_id, acc_desc, acc_balance".
				      " FROM Accounts".
				      " WHERE".($balans ? "" : " NOT")." acc_balres".
				      "  AND acc_struct = ?".
				      "  AND acc_balance <> 0".
				      " ORDER BY acc_id", $vd->[0]);

		my $dsstot = 0;
		my $csstot = 0;
		while ( $rr = $sth->fetchrow_arrayref ) {
		    $rep->addline('H1', $hvd->[0], $hvd->[1], undef, undef)
		      unless $detail < 1 || $did_hvd++;
		    $rep->addline('H2', $vd->[0], " ".$vd->[1], undef, undef)
		      unless $detail < 2 || $did_vd++;
		    my ($acc_id, $acc_desc, $acc_balance) = @$rr;
		    if ( $acc_balance >= 0 ) {
			$dsstot += $acc_balance;
			$rep->addline('D2', $acc_id, $acc_desc, $acc_balance, undef)
			  if $detail >= 2;
		    }
		    else {
			$csstot -= $acc_balance;
			$rep->addline('D2', $acc_id, $acc_desc, undef, -$acc_balance)
			  if $detail >= 2;
		    }
		}
		$sth->finish;
		if ( $detail >= 1 && ($csstot || $dsstot) ) {
		    $rep->addline('T2', $vd->[0], ($detail > 1 ? "Totaal " : "").$vd->[1], $dsstot, $csstot);
		}
		$cstot += $csstot;
		$dstot += $dsstot;
	    }
	    if ( $detail >= 0  && ($cstot || $dstot) ) {
		$rep->addline('T1', $hvd->[0], ($detail > 0 ? "Totaal " : "").$hvd->[1], $dstot, $cstot);
	    }
	    $ctot += $cstot;
	    $dtot += $dstot;
	}

    }
    else {
	$sth = $::dbh->sql_exec("SELECT acc_id, acc_desc, acc_debcrd, acc_balance".
			      " FROM Accounts".
			      " WHERE".($balans ? "" : " NOT")." acc_balres".
			      "  AND acc_balance <> 0".
			      " ORDER BY acc_id");

	while ( $rr = $sth->fetchrow_arrayref ) {
	    my ($acc_id, $acc_desc, $acc_debcrd, $acc_balance) = @$rr;
	    # $acc_balance = -$acc_balance unless $acc_debcrd;
	    if ( $acc_balance >= 0 ) {
		$dtot += $acc_balance;
		$rep->addline('D', $acc_id, $acc_desc, $acc_balance, undef);
	    }
	    else {
		$ctot -= $acc_balance;
		$rep->addline('D', $acc_id, $acc_desc, undef, -$acc_balance);
	    }
	}
	$sth->finish;
    }

    my ($w, $v) = $balans ? qw(Winst Verlies) : qw(Verlies Winst);
    if ( $dtot != $ctot ) {
	if ( $dtot >= $ctot ) {
	    $rep->addline('V', '', "<< $w >>", undef, $dtot - $ctot || "00");
	    $ctot = $dtot;
	}
	else {
	    $rep->addline('V', '', "<< $v >>", $ctot - $dtot || "00", undef);
	    $dtot = $ctot;
	}
    }
    $rep->addline('T', '', 'TOTAAL '.($balans ? "Balans" : "Resultaten"), $dtot, $ctot);
}

1;
