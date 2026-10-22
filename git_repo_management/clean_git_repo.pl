#!/usr/bin/perl 

# This was the script I used to clean up old commits in NS configuration_data repo on 2020-03-03
# This script was run in the git repo in question, to allow got commands to work.
# The source file was created via: for branch in `git branch -r --merged | grep -v HEAD`; do echo -e `git show --format="%ci %cr %an" $branch | head -n 1` \\t$branch; done | sort -r
# I then edited the file by hand to weed out recent entries.  (It being mostly in chronological order.)
# So obviously that is a 'TODO' for later
# Information source: https://railsware.com/blog/git-housekeeping-tutorial-clean-up-outdated-branches-in-local-and-remote-repositories/

use strict;
use warnings;

my $line;
my @parts;
my $part;
my $git = "/usr/bin/git";

open(FILE, "/Users/mrex/GIT/SE/configuration_data/year_or_more.txt");

while(<FILE>) {
	chomp;
	#print $_;
	@parts = split(/\s/);
	foreach $part(@parts) {
 		#print "--$part\n";
		if($part =~ m/origin\/(\w+-\d+.*)$/) {
		#if($part =~ /oriin/) {
			print "git push origin --delete $1\n";
			system("$git push origin --delete $1");
		}
	}
}
close(FILE)
