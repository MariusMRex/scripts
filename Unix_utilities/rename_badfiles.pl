#!/usr/bin/perl 

use strict;
use warnings;

my $FIND = "/usr/bin/find";
my $MV = "/bin/mv";
my $FILE;
my $NEWFILE;
my $STEM;
my $LASTFILE;
my $FILEBASE = "/Volumes/Magazine_Editorial";
my @BAD_FILES = `$FIND $FILEBASE -depth -name "*~*" -print`;
my $REPLACEMENT = "_";
my $QUOTE = "\"";
my $COUNT = '0';

foreach $FILE (@BAD_FILES) {
	if($FILE =~ /(^\/.*\/)(.*$)/) { 
		$STEM = $1;
		$LASTFILE = $2;
		chomp($FILE);
		chomp($LASTFILE);
		# Replace all space characters with underscores
		$LASTFILE =~ s/\s+/_/g;
		# Replace wierd charcaters with underscores
		$LASTFILE =~ s/~/_/g;
		$LASTFILE =~ s/\(/_/g;
		$LASTFILE =~ s/\)/_/g;
		$LASTFILE =~ s/\@/_/g;
		$LASTFILE =~ s/\$/_/g;
		$NEWFILE = "$STEM$LASTFILE";
		unless($FILE eq $NEWFILE) {
			print "Oldfile $FILE...\n ";
			system("$MV $QUOTE$FILE$QUOTE $QUOTE$NEWFILE$QUOTE");
			print "-- Changing to $NEWFILE\n\n\n";
			++$COUNT;
		}
	}
	
	#if($FILE =~ /(.*\/\w*)(\~)(\w*.*)/) { 
	#	my $NEWFILE = "$1$REPLACEMENT$3";
	#	print "-- Changing to $NEWFILE\n";
	#	#rename($FILE,$NEWFILE);
	#}
	#if($FILE =~ /(.*\/)(\~)(\w*.*)/) { 
	#	my $NEWFILE = "$1$REPLACEMENT$3";
	#	$NEWFILE =~ s/\s+/_/g;
	#	print "-- Changing to $NEWFILE\n";
	#	#rename($FILE,$NEWFILE);
	#	system("$MV $QUOTE$FILE$QUOTE $NEWFILE");
	#}
}
print "Changed $COUNT files.\n";
