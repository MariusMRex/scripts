#!/usr/bin/perl 

use strict;
use warnings;

my $FIND = "/usr/bin/find";
my $MV = "/bin/mv";
my $RM = "/bin/rm";
my $UNZIP = "/usr/bin/unzip";
my $GUNZIP = "/usr/bin/gunzip";
my $FILE;
my $NEWFILE;
my $STEM;
my $LASTFILE;
my $FILEBASE = "/home/marius/Desktop/email-reports";
my @BAD_FILES = `$FIND $FILEBASE -depth -print`;
my $REPLACEMENT = "_";
my $QUOTE = "\"";
my $COUNT = '0';

foreach $FILE (@BAD_FILES) {
	if($FILE =~ /.*(gz|zip|xml)$/) { 
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
		$NEWFILE =~ s/\!/_/g;
		unless($FILE eq $NEWFILE) {
			print "Oldfile $FILE...\n ";
			system("$MV $QUOTE$FILE$QUOTE $QUOTE$NEWFILE$QUOTE");
			print "-- Changing to $NEWFILE\n\n\n";
                        if($NEWFILE =~ /.*.zip/) {
				system("$UNZIP $NEWFILE");
			}
                        if($NEWFILE =~ /.*.gz/) {
				system("$GUNZIP $NEWFILE");
			}
			#system("$RM $NEWFILE");
			++$COUNT;
		}
	} else {
        chomp $FILE;
	#print "$QUOTE$FILE$QUOTE Did not match\n";
        }
	
}
print "Changed $COUNT files.\n";
