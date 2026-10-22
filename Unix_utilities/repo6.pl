#!/usr/bin/perl
# Quick script to drop a package in the venda6 repo

use strict;
use warnings;

my $REPOPATH = "/export/mirror.dev.venda.com/yum/6/x86_64";
my $RPM = $ARGV[0];
chomp($RPM);

unless($RPM =~ /^\w.*\.rpm$/) {
	print "Useage: $0 SOME_NAME.rpm\n";
	exit 1;
}

print "sudo mv $RPM $REPOPATH\n";
system("sudo mv $RPM $REPOPATH");

print "sudo chown root:root $REPOPATH/$RPM\n";
system("sudo chown root:root $REPOPATH/$RPM");

print "sudo chmod 755 $REPOPATH/$RPM\n";
system("sudo chmod 755 $REPOPATH/$RPM");

print "sudo createrepo -c cache -s sha $REPOPATH\n";
system("sudo createrepo -c cache -s sha $REPOPATH");
