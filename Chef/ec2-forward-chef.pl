#!/usr/bin/perl 

use strict;
use warnings;

# Create a ssh forward to the current chef server through the proxy.
# Since the domain name varies, this script needs an augment

my $CHEF_SERVER = $ARGV[0];
my $CMD = "ssh -L 3128:localhost:3128 $CHEF_SERVER";

unless($CHEF_SERVER =~ /ec2-.*/) {
	print "Please provide the public domain name of the chef server in ec2 via the command line\n";
	exit 1;
}

# Assuming we get an augment, run the command
system("$CMD");
