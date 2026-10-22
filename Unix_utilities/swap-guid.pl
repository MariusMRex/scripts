#!/usr/bin/perl -T
# 
# Testing this functionality in various compiles of perl.
# Source of script: http://www.perlmonks.org/?displaytype=print;node_id=791479;replies=1

use strict;

my $user  = 'jabber';
my $group = 'jabber';
my $uid = getpwnam($user) || die "Cannot identify uid";
my $gid = getgrnam($group) || die "Cannot identify gid";

printf("Current Effective User ID: %s\n", $>);
printf("Current Effective Group IDs: %s\n", $));
printf("Requested User ID: %s\n", $uid);
printf("Requested Group ID: %s\n", $gid);

print "Changing Effective IDs\n";

$) = $gid;
$> = $uid;

printf("Current Effective User ID: %s\n", $>);
printf("Current Effective Group IDs: %s\n", $));
