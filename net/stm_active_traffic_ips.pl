#!/usr/bin/perl 
# 
# I just want to know what Traffic IPs are active on what STM node.
# 2013-11-19 marius@venda.com

use strict;
use warnings;
use File::Glob ':glob';

my $DIR_BASE = "/usr/local/zeus/zxtm/conf/flipper";
my $TRAFFIC_IP;
my @TRAFFIC_GROUP = bsd_glob("$DIR_BASE/*", GLOB_NOSORT);
my $GROUP;
my $NODE = $ARGV[0];
my $SEARCH_NODE;
my $LINE;
my $FOUND;
my $ENABLED;
my @ENABLED_IP;
my @DISABLED_IP;
my $IP;
my $RESULT;

unless($NODE =~ /wt-?blb\d\d/) {
        print "Please enter the host name of a BLB to search for.  Exp: wt-blb09\n";
        exit 1;
}

$SEARCH_NODE = "$NODE.dc-1.uk.venda.com";
print "My Search node: $SEARCH_NODE\n";
sleep 1;

foreach $GROUP(@TRAFFIC_GROUP) {
        open(SITE, "$GROUP");
        # reset our variables
        $FOUND = '0';
        $ENABLED = 'N';
        $RESULT='';
        while(<SITE>) {
                $LINE = $_;
                chomp($LINE);
                if($FOUND == "1") {
                        if($LINE =~ /slaves\s.*/) {
                                if($LINE =~ /slaves\s.*$SEARCH_NODE/) {
                                        last;
                                } else {
                                        $TRAFFIC_IP = substr $GROUP, 34;
                                        if($ENABLED eq 'Y') {
                                                $RESULT="$TRAFFIC_IP: $SEARCH_NODE is active node";
                                                push(@ENABLED_IP,$RESULT);
                                        } else {
                                                $RESULT="$TRAFFIC_IP: $SEARCH_NODE is active node";
                                                push(@DISABLED_IP,$RESULT);
                                        }
                                }
                        } else {
                                next;
                        }
                }
                if($LINE =~ /ipaddresses\s.*\d+\.\d+\.\d+\.\d+\./) {
                        next;
                } elsif($LINE =~ /enabled\sYes/) {
                        $ENABLED = 'Y';
                        next;
                } elsif($LINE =~ /enabled\sNo/) {
                        $ENABLED = 'N';
                       next;
                } elsif($LINE =~ /mode\s+singlehosted/) {
                        next;
                } elsif($LINE =~ /location.*/) {
                        next;
                } elsif($LINE =~ /machines\s.*$SEARCH_NODE/) {
                        #print "$GROUP: $LINE\n";
                        #print "...Found a match is machines line: $GROUP\n";
                        $FOUND = "1";
                        next;
                }
        }
}

# Enabled Traffic IPs
print "\nEnabled Traffic IPs:\n---------------\n";
foreach $IP(@ENABLED_IP) {
        print "$IP\n";
}

# Disabled Traffic IPS
print "\nDisabled Traffic IPs:\n---------------\n";
foreach $IP(@DISABLED_IP) {
        print "$IP\n";
}

