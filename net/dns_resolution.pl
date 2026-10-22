#!/usr/bin/perl
use strict;
use warnings;

use Net::DNS::Resolver;

#my $hostname = 'perl.org';
my $ip = '10.0.0.149';
my $res = Net::DNS::Resolver->new;

my $query = $res->search($ip);

if ($query) {
  foreach my $rr ($query->answer) {
    next unless $rr->type eq "A";
    print "Found an A record: ".$rr->address;
    print "\n";
  }
}
