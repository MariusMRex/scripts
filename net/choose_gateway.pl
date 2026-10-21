#!/usr/bin/perl

use strict;
use warnings;

# Script for FreeBSD gateway in STM offices.
# Ping current gateway, if pings fail, migrate to other gatway
# Script currently unfinished.

my $AWK = "/bin/awk";
my $GREP = "/bin/grep";
my $NETSTAT = "/bin/netstat";
my $PING = "/bin/ping";
my $AWK_ROUTE = "$AWK '{print $2}'";
my $AWK_PING = "$AWK '{print $7}'";

my $NAMESERVER = "209.131.117.53";	#Datagram nameserver
my $DS3_ROUTE = "63.208.173.193";
my $EOC_ROUTE = "192.168.0.6";
my $OLD_ROUTE;
my $NEW_ROUTE;
my $CURRENT_ROUTE = `$NETSTAT -rn | $GREP default| $AWK_ROUTE";
my $THRESHHOLD = "60";			# If we have more packet loss then this %, switch

# Ping test
my $PACKET_FAILURE = `$PING -c 10 $NAMESERVER| $GREP " 0% packet loss" | $AWK_PING`;

if($PING_TEST =~ /\d\d+/) {
	# Hey, at least we got a number.
	if($PACKET_FAILURE < $THRESHHOLD) {
		# We are doing O.K.  I think
		exit 0;
	} elsif($PACKET_FAILURE > $THRESHHOLD) {
		# We need to swap gateways.

		# Probably do not need a chomp, but just in case.
		chomp($CURRENT_ROUTE);
		if($CURRENT_ROUTE =~ /$DS3_ROUTE/) {
			$OLD_ROUTE = $DS3_ROUTE;
			$NEW ROUTE = $EOC_ROUTE;
		} elsif($CURRENT_ROUTE =~ /$EOC_ROUTE/) {
			$OLD_ROUTE = $EOC_ROUTE;
			$NEW_ROUTE = $DS3_ROUTE;
		} else {
		print "I am confused: $CURRENT_ROUTE\n";
		exit 1;
}
