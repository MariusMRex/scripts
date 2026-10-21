#!/usr/bin/perl

use strict;
use warnings;
use Net::SMTP;

# When Earthlink blocks you, one has to email them to get unblocked
# From ReturnPath:
# 
# So removing a block at Earthlink needs to be done through email, and can only be done one IP
# at a time. The process, however, is easy and they remove the block very quickly.
# 
# For each IP that is blocked, the message should look like this:
#  
#  To: blockedbyearthlink@abuse.earthlink.net
#  Subject line: Blocked 12.12.122.122
#  Body: include the bounce code
#   
# A trick so that you don't have to fish through a ton of bounce codes is to get one bounce 
# code and switch out the IP in each one. The blocks removals are processed by a computer 
# and in my experience the only thing they look at is the subject line.
# 

my $smtp;

my %ips = (
    1  => '10.131.125.102', 2  => '10.131.125.103', 3  => '10.131.125.104', 
    4  => '10.131.125.105', 5  => '10.131.125.106', 6  => '10.131.125.108', 
    7  => '10.131.125.109', 8  => '10.131.125.110', 9  => '10.131.125.111', 
    10 => '10.131.125.112', 11 => '10.131.125.114', 12 => '10.131.125.115', 
    13 => '10.131.125.116', 14 => '10.131.125.117', 15 => '10.131.125.118', 
);

my $last_oct = "118";

$smtp = Net::SMTP->new("10.131.125.$last_oct",
	Hello => 'queue.shermanstravel.com',
	Timeout => 60,
	Debug   => 1,
	);

# Can we authenticate?
my $from = "top25\@shermanstravel.com";
my $to = "blockedbyearthlink\@abuse.earthlink.net";

$smtp->mail("$from");
$smtp->recipient("$to");

$smtp->data;

$smtp->datasend("From: $from\n");
$smtp->datasend("To: $to\n");
$smtp->datasend("Subject: Blocked 209.131.125.$last_oct\n");
$smtp->datasend("\n");

# Send Body
$smtp->datasend("550 IP 209.131.125.$last_oct is blocked by EarthLink. Go to earthlink.net/block for details.,mx2.earthlink.net (209.86.93.227)");

# End message
$smtp->dataend;
$smtp->quit;

