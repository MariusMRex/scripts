#!/usr/bin/perl 

use strict;
use warnings;

# Check inputs
unless($ARGV[0]) {
	print "This script requires two augments, an initial search string, and what to replace it with.\n";
        exit 1;
}
unless($ARGV[1]) {
	print "This script requires two augments, an initial search string, and what to replace it with.\n";
        exit 1;
}

my $FIND = "/usr/bin/find";
my $MV = "/bin/mv";
my $OLDSTRING = $ARGV[0];
my $NEWSTRING = $ARGV[1];
chomp($NEWSTRING);
chomp($OLDSTRING);
my $FILE;
my $NEWFILE;
my $STEM;
my $SUFFIX;
my $LASTFILE;
my $FILEBASE = `/bin/pwd`;
chomp($FILEBASE);
my @BAD_FILES = `$FIND $FILEBASE -maxdepth 1 -name "*$OLDSTRING*" -print`;
my $LENGTH = @BAD_FILES;
print "$FIND $FILEBASE -maxdepth 1 -name -maxdepth 0 \"*$OLDSTRING*\" -print\n";
my $REPLACEMENT = "-";
my $QUOTE = "\"";
my $COUNT = '0';

# Did our find operation find any files?
if ($LENGTH < 1) {
	print "Sorry -- Initial string \"$OLDSTRING\" did not find any files.\n";
        exit 1;
}

foreach $FILE (@BAD_FILES) {
        #print "$FILE";
	if($FILE =~ /(^\/.*\/)($OLDSTRING)-(\d+.NEF(\.xmp)?)$/) { 
		$STEM = $1;
		$LASTFILE = $2;
		$SUFFIX = $3;
		chomp($FILE);
		chomp($LASTFILE);
        	#print "So $STEM + $LASTFILE + $SUFFIX\n";
		$LASTFILE =~ s/$OLDSTRING/$NEWSTRING-/g;
		$NEWFILE = "$STEM$LASTFILE$SUFFIX";
		unless($FILE eq $NEWFILE) {
			print "Oldfile $FILE...\n ";
			system("$MV $QUOTE$FILE$QUOTE $QUOTE$NEWFILE$QUOTE");
			print "-- Changing to $NEWFILE\n\n\n";
			++$COUNT;
		}
	} else {
               print "No Match - $FILE\n";
        }
}
        
print "Changed $COUNT files.\n";
