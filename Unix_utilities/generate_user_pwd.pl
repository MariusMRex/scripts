#!/usr/bin/perl -wl

use strict;
use warnings;
use Term::ReadKey;
use Crypt::PasswdMD5 qw(unix_md5_crypt);

my @salt = ( '.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z' );
print "Please enter a Password";
ReadMode('noecho');
my $password = ReadLine(0);
ReadMode(0);
chomp $password;
my %encrypted;
$encrypted{md5} = unix_md5_crypt( $password, gensalt(8) );
$encrypted{sha} = crypt($password,'$5$'. gensalt(8) );

print "$_ $encrypted{$_}" for sort keys %encrypted;
# uses global @salt to construct salt string of requested length

sub gensalt {
	my $count = shift;
	my $salt;
	for (1..$count) {
		$salt .= (@salt)[rand @salt];
	}
	return $salt;
}
