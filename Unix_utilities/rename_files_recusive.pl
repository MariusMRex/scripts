#!/usr/bin/perl 

use strict;
use warnings;

my $FIND = "/usr/bin/find";
my $MV = "/bin/mv";
my $FILE;
my $NEWFILE;
my $STEM;
my $LASTFILE;
my $FILEBASE = '/Volumes/Magazine_Editorial';
my @BAD_FILES = `$FIND $FILEBASE -print`;
my $REPLACEMENT = "_";
my $QUOTE = "\"";
my $COUNT = '0';

foreach $FILE (@BAD_FILES) {
		chomp($FILE);
		$NEWFILE = $FILE;
		# Replace all space characters with underscores
		$NEWFILE =~ s/\s+/_/g;
		# Replace wierd characters with underscores
		$NEWFILE =~ s/~/_/g;
		$NEWFILE =~ s/\(/_/g;
		$NEWFILE =~ s/\)/_/g;
		$NEWFILE =~ s/\@/_/g;
		$NEWFILE =~ s/\$/_/g;
		$NEWFILE =~ s/\*//g;
		$NEWFILE =~ s/:/-/g;
		# See if we can fix the spaces issue in $FILE
		$FILE =~ s/\s+/\\ /g;
		$FILE =~ s/\*/\\*/g;
		unless($FILE eq $NEWFILE) {
			print "Oldfile $FILE...\n ";
			#system("$MV $QUOTE$FILE$QUOTE $QUOTE$NEWFILE$QUOTE");
			system("$MV $FILE $NEWFILE");
			print "-- Changing to $NEWFILE\n\n\n";
			++$COUNT;
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
