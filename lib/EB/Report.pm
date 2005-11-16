# Report.pm -- Report tools
# RCS Info        : $Id: Report.pm,v 1.1 2005/11/16 13:59:14 jv Exp $
# Author          : Johan Vromans
# Created On      : Mon Nov 14 21:46:04 2005
# Last Modified By: Johan Vromans
# Last Modified On: Wed Nov 16 14:58:41 2005
# Update Count    : 28
# Status          : Unknown, Use with caution!

package main;

our $dbh;

package EB::Report;

use strict;
use warnings;
use EB;
use EB::Finance;

my $trace = 0;

sub GetTAccountsBal {
    shift;
    my ($end) = @_;

    # balans(r, t) = balans(r, t0) + sum(journaal, r, t0..t) + sum(boekjaarbalans, r, t' < t)

    # balans(r, t0)
    $dbh->sql_exec("SELECT acc_id,acc_desc,acc_balres,acc_debcrd,".
		   "acc_ibalance,acc_ibalance AS acc_balance,acc_struct".
		   " INTO TEMP TAccounts".
		   " FROM Accounts")->finish;

    # sum(journaal, r, t0..t)
    my $sth = $dbh->sql_exec("SELECT jnl_acc_id,acc_balance,SUM(jnl_amount)".
			     " FROM Journal,TAccounts".
			     " WHERE acc_id = jnl_acc_id".
			     " AND jnl_date <= ?".
			     " GROUP BY jnl_acc_id,acc_balance,acc_ibalance",
			     $end);

    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($acc_id, $acc_balance, $sum) = @$rr;
	next unless $sum;
	$sum += $acc_balance;
	warn("!".__x("Balansrekening {acct}, saldo aangepast naar {exp}",
		     acct => $acc_id, exp => numfmt($sum)) . "\n") if $trace;
	$dbh->sql_exec("UPDATE TAccounts".
		       " SET acc_balance = ?".
		       " WHERE acc_id = ?",
		       $sum, $acc_id)->finish;
    }

    # sum(boekjaarbalans, r, t' < t)
    $sth = $dbh->sql_exec("SELECT bkb_acc_id, bkb_balance".
			  " FROM Boekjaarbalans".
			  " WHERE bkb_end < ?", $end);
    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($acc_id, $acc_balance) = @$rr;
	warn("!".__x("Balansrekening {acct}, saldo aangepast met {exp}",
		     acct => $acc_id, exp => numfmt(-$acc_balance)) . "\n") if $trace;
	$dbh->sql_exec("UPDATE TAccounts".
		       " SET acc_balance = acc_balance - ?".
		       " WHERE acc_id = ?",
		       $acc_balance, $acc_id)->finish;
    }

    # Return temp table.
    "TAccounts";
}

sub GetTAccountsAll {
    push(@_, 1);
    goto &GetTAccountsRes;
}

sub GetTAccountsRes {
    shift;
    my ($begin, $end, $all) = @_;

    # beginsaldo(r, t1, t2) = sum(journaal, r, t0..t1) + sum(boekjaarbalans, r, t' < t1)
    # eindsaldo(r, t1, t2) = beginsaldo(r, t1, t2) + sum(journaal, r, t1..t2)

    # init
    if ( $all ) {
	$dbh->sql_exec("SELECT acc_id,acc_desc,acc_balres,acc_debcrd,".
		       "acc_ibalance,acc_balance,acc_struct".
		       " INTO TEMP TAccounts".
		       " FROM Accounts")->finish;
    }
    else {
	$dbh->sql_exec("SELECT acc_id,acc_desc,acc_balres,acc_debcrd,".
		       "0 AS acc_ibalance,0 AS acc_balance,acc_struct".
		       " INTO TEMP TAccounts".
		       " FROM Accounts".
		       " WHERE NOT acc_balres")->finish;
    }

    # beginsaldo(r, t1, t2) = sum(journaal, r, t0..t1) ...
    my $sth = $dbh->sql_exec("SELECT jnl_acc_id,SUM(jnl_amount)".
			     " FROM Journal,TAccounts".
			     " WHERE acc_id = jnl_acc_id".
			     " AND jnl_date < ?".
			     " GROUP BY jnl_acc_id",
			     $begin);

    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($acc_id, $sum) = @$rr;
	next unless $sum;
	warn("!".__x("Resultaatrekening {acct}, beginsaldo is {exp}",
		     acct => $acc_id, exp => numfmt($sum)) . "\n") if $trace;
	$dbh->sql_exec("UPDATE TAccounts".
		       " SET acc_ibalance = acc_ibalance + ?".
		       " WHERE acc_id = ?",
		       $sum, $acc_id)->finish;
    }

    # ... + sum(boekjaarbalans, r, t' < t1)
    $sth = $dbh->sql_exec("SELECT bkb_acc_id, bkb_balance".
			  " FROM Boekjaarbalans".
			  " WHERE bkb_end < ?", $begin);
    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($acc_id, $acc_balance) = @$rr;
	warn("!".__x("Resultaatrekening {acct}, saldo aangepast met {exp}",
		     acct => $acc_id, exp => numfmt(-$acc_balance)) . "\n") if $trace;
	$dbh->sql_exec("UPDATE TAccounts".
		       " SET acc_ibalance = acc_ibalance - ?".
		       " WHERE acc_id = ?",
		       $acc_balance, $acc_id)->finish;
    }

    # eindsaldo(r, t2) = beginsaldo(r, t1) + sum(journaal, r, t1..t2)
    $sth = $dbh->sql_exec("SELECT jnl_acc_id,SUM(jnl_amount)".
			     " FROM Journal,TAccounts".
			     " WHERE acc_id = jnl_acc_id".
			     " AND jnl_date >= ?".
			     " AND jnl_date <= ?".
			     " GROUP BY jnl_acc_id",
			     $begin,
			     $end);

    while ( my $rr = $sth->fetchrow_arrayref ) {
	my ($acc_id, $sum) = @$rr;
	next unless $sum;
	warn("!".__x("Resultaatrekening {acct}, mutaties is {exp}",
		     acct => $acc_id, exp => numfmt($sum)) . "\n") if $trace;
	$dbh->sql_exec("UPDATE TAccounts".
		       " SET acc_balance = acc_ibalance + ?".
		       " WHERE acc_id = ?",
		       $sum, $acc_id)->finish;
    }

    "TAccounts";
}

sub GetTAccountsCopy {
    shift;
    $dbh->sql_exec("SELECT acc_id,acc_desc,acc_balres,acc_debcrd,acc_ibalance,acc_balance,acc_struct".
		   " INTO TEMP TAccounts".
		   " FROM Accounts")->finish;
    "TAccounts";
}

1;
