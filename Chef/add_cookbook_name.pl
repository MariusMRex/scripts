#!/usr/bin/perl
#
#This is a quick script to look into the chef cookbook directory and add the 'name' attribute to any metadata.rb files that are missing it.

use File::Glob ':glob';

my $COOKBOOK_HOME = "/Users/marius/GIT/chef-repo/cookbooks";
#my @COOKBOOKS = bsd_glob("$COOKBOOK_HOME/*", GLOB_NOSORT);
my @METADATA_FILES = bsd_glob("$COOKBOOK_HOME/*/metadata*", GLOB_NOSORT);
my $METADATA_FILE;
my $METADATA_HEAD;
my $COOKBOOK;
my $FILE;

foreach $FILE(@METADATA_FILES) {
	#print "$FILE\n";
	if($FILE =~ /$COOKBOOK_HOME\/(.*)\/(metadata.rb$)/) {
		$COOKBOOK = $1;
		$METADATA_FILE = $2;
		$METADATA_HEAD = `/usr/bin/head $FILE`;
		unless($METADATA_HEAD =~ /^name\s+/) {
			print "Fixing $COOKBOOK...";
			$OLD_FILE = $FILE;
			$NEW_FILE = "$FILE.tmp$$";
			$BACKUP = "$FILE.bak";
			open(OLD, "< $OLD_FILE")         or die "can't open $OLD_FILE: $!";
			open(NEW, "> $NEW_FILE")         or die "can't open $NEW_FILE: $!";
			print NEW "name               '$COOKBOOK'\n";
			while (<OLD>) {
				print NEW "$_";
			}
			close(OLD)                  or die "can't close $OLD_FILE: $!";
			close(NEW)                  or die "can't close $NEW_FILE: $!"; 
			rename($OLD_FILE, $BACKUP)          or die "can't rename $OLD_FILE to $BACKUP: $!";
			rename($NEW_FILE, $OLD_FILE)          or die "can't rename $OLD_FILE to $NEW_FILE: $!";
			print "Done.\n";
		} else {
			print "$COOKBOOK Looks Good!\n";
		}
	}
}
