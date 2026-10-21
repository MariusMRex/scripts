#!/usr/local/bin/perl -w
use strict;

# This should work, but I just want to test it before I commit to production

my @EMAIL = qw( bob@aol.com saurval@gmail.com sue@bellsouth.net zzzzzr@sbcglobal.net MariusRex@netscape.net 00betty00@att.net );
my $EMAIL;

foreach $EMAIL (@EMAIL) {
	print "$EMAIL -> ";
	if($EMAIL =~ /(aol.com|bellsouth.net|sbcglobal.net|att.net)$/) {
		print "changing title.\n";
	} else {
		print "accepted as is.\n";
	}
}

