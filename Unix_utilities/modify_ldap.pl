#!/usr/bin/perl

use warnings;
use strict;

my $FILE = $ARGV[0];
my $ROOT_DN = "cn=root,dc=uk,dc=venda";
my $LDAP_MOD = "/usr/bin/ldapmodify";

unless ($FILE) {
	print "Useage: $0 somefile.ldif\n";
	exit 1;
}

chomp($FILE);

#print "$LDAP_ADD -x -D \"$ROOT_DN\" -W -f $FILE\n";
system("$LDAP_MOD -x -D \"$ROOT_DN\" -W -f $FILE");

