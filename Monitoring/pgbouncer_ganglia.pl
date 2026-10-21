#!/usr/bin/perl
# Can we turn nagios checks into ganglia graphs
#
# Example checks
# /usr/lib64/nagios/plugins/check_postgres.pl -p 6434 --action=pgbouncer_backends -w '75%' -c '95%' --host 10.17.24.103 -u postgres
# POSTGRES_PGBOUNCER_BACKENDS OK: DB "pgbouncer" (host:10.17.24.103) (port=6434) 1 of 5000 connections (1%) | time=0.00s 'boohoo'=0;3750;4750;0;5000 'boohooindex'=0;3750;4750;0;5000 'pgbouncer'=1;3750;4750;0;5000 

use strict;
use warnings;

my $GMETRIC = "/usr/bin/gmetric";
my $CHECK_POSTGRES = "/usr/lib64/nagios/plugins/check_postgres.pl";
my $PORT = '6434';
my $TOTAL_CONN;
my $SITE;
my $SITE_CONNECTIONS;
my @CONNECTION_DATA;
my $POOL;

my $BACKEND_CHECK = `/usr/lib64/nagios/plugins/check_postgres.pl -p $PORT --action=pgbouncer_backends -w '75%' -c '95%' --host 10.17.24.103 -u postgres`;
chomp($BACKEND_CHECK);
my $CLIENT_MAXWAIT_CHECK = `/usr/lib64/nagios/plugins/check_postgres.pl -p $PORT --action=pgb_pool_maxwait -w 5 -c 15 --host 10.17.24.103 -u postgres`;
my $CLIENT_WAIT;
my @WAITING_STATS;
my $CLIENT_WAITING_CHECK = `/usr/lib64/nagios/plugins/check_postgres.pl -p $PORT --action=pgb_pool_cl_waiting -w 3 -c 8 --host 10.17.24.103 -u postgres`;

#if($BACKEND_CHECK =~ /POSTGRES_PG.*:\sDB\s\"pgbouncer\"\s\(host:\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\)\s\(port=6434\)\s(\d+)\sof\s\d+\sconnections\s\(\d+%\)\s\|\stime=\d+\.\d+s\s\'(\w+)\'=(\d+)/) {
#       #print "Check caught string.\n";
#       $TOTAL_CONN = $1;
#       $SITE = $2;
#       $SITE_CONNECTIONS = $3;
#       print "TOTAL_CONN = $TOTAL_CONN\n";
#       print "$SITE = $SITE_CONNECTIONS\n";
#} else {
#       print "String did not match: $BACKEND_CHECK\n"
#}


#print "-----\n";

if($BACKEND_CHECK =~ /POSTGRES_PG.*:\sDB\s\"pgbouncer\"\s\(host:\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\)\s\(port=$PORT\)\s(\d+)\sof\s\d+\sconnections\s\(\d+%\)\s\|\stime=\d+\.\d+s\s(\'(\w+)\'=(\d+).*\s)/) {
        #print "Check caught string.\n";
        $TOTAL_CONN = $1;
        $SITE_CONNECTIONS = $2;
        #print "TOTAL_CONN = $TOTAL_CONN\n";
        #print "$GMETRIC --name="PGBouncer Total Connections Port $PORT" 
        #print "SITE_CONNECTIONS = $SITE_CONNECTIONS\n";
        @CONNECTION_DATA = split / /, $SITE_CONNECTIONS;
        foreach $POOL(@CONNECTION_DATA) {
                chomp($POOL);
                if($POOL =~ /\'(\w+)\'=(\d+);/) {
                        $SITE = $1;
                        $SITE_CONNECTIONS = $2;
                        print "$SITE = $SITE_CONNECTIONS\n";
                        print "-----\n";
                } else {
                        print "BACKENDS: string for POOL did not match: $POOL\n";
                }
        }
} else {
        print "String did not match: $BACKEND_CHECK\n"
}


# marius@wtci01 nagios]$ sudo /usr/lib64/nagios/plugins/check_postgres.pl -p 6434 --action=pgb_pool_maxwait -w 5 -c 15 --host 10.17.24.103 -u postgres
# POSTGRES_PGB_POOL_MAXWAIT OK: DB "pgbouncer" (host:10.17.24.103) (port=6434) boohoo=0 * boohooindex=0 * pgbouncer=0 | time=0.00s time=0.00s time=0.00s 

if($CLIENT_MAXWAIT_CHECK =~ /POSTGRES_PG.*:\sDB\s\"pgbouncer\"\s\(host:\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\)\s\(port=$PORT\)\s(.*)\|.*/) {
        $CLIENT_WAIT = $1;
        print "$CLIENT_WAIT\n";
        @WAITING_STATS = split / /, $CLIENT_WAIT;
        foreach $POOL(@WAITING_STATS) {
                chomp($POOL);
                if($POOL =~ /\s?(\w+)=(\d+)/) {
                        $SITE = $1;
                        $SITE_CONNECTIONS = $2;
                        print "$SITE maxwait time is: $SITE_CONNECTIONS\n";
                        print "-----\n";
                } elsif($POOL =~ /\*/) {
                        #print "skipping star\n";
                        next;
                } else {
                        print "MAXWAIT: String for POOL did not match: $POOL\n";
                }
        }
} else {
        print "String did not match: $CLIENT_MAXWAIT_CHECK\n"
}

# [marius@wtci01 nagios]$ sudo /usr/lib64/nagios/plugins/check_postgres.pl -p 6432 --action=pgb_pool_cl_waiting -w 3 -c 8 --host 10.17.24.103 -u postgres
# POSTGRES_PGB_POOL_CL_WAITING OK: DB "pgbouncer" (host:10.17.24.103) (port=6432) boohoo=0 * boohooindex=0 * pgbouncer=0 | time=0.00s time=0.00s time=0.00s

if($CLIENT_WAITING_CHECK =~ /POSTGRES_PG.*:\sDB\s\"pgbouncer\"\s\(host:\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\)\s\(port=$PORT\)\s(.*)\|.*/) {
        $CLIENT_WAIT = $1;
        print "$CLIENT_WAIT\n";
        @WAITING_STATS = split / /, $CLIENT_WAIT;
        foreach $POOL(@WAITING_STATS) {
                chomp($POOL);
                if($POOL =~ /\s?(\w+)=(\d+)/) {
                        $SITE = $1;
                        $SITE_CONNECTIONS = $2;
                        print "$SITE wait time is: $SITE_CONNECTIONS\n";
                        print "-----\n";
                } elsif($POOL =~ /\*/) {
                        #print "skipping star\n";
                        next;
                } else {
                        print "WAITTIME: string for POOL did not match: $POOL\n";
                }
        }
} else {
	print "String did not match: $CLIENT_WAITING_CHECK\n"
}
