#!/usr/bin/perl 
#===============================================================================
#
#         FILE: create-git-index.pl
#
#        USAGE: ./create-git-index.pl  
#
#  DESCRIPTION: Create a quick index file for the base of the git repo
#
#      OPTIONS: NA
# REQUIREMENTS: Assumes git repos are in /home/git/repositories
#         BUGS: unknown
#        NOTES: NA
#       AUTHOR: Marius Rex (mariusrex@venda.com), 
# ORGANIZATION: Venda LTd.
#      VERSION: 1.0
#      CREATED: 05/05/2014 04:44:39 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

use File::Glob ':glob';

my $REPO_BASE = "/home/git/repositories";
my $INDEXFILE = "$REPO_BASE/index.html";
my $DIR;
#my @DIRS = bsd_glob("$REPO_BASE/*", GLOB_NOSORT);
my @DIRS = bsd_glob("$REPO_BASE/*");

open(HTTP_INDEX, ">$INDEXFILE");
print HTTP_INDEX "<html>\n  <head>\n    <title>\n      Git http access\n    </title>\n  </head>\n  <body>\n";
print HTTP_INDEX "    <h1>Available GIT repos</h1>\n";

foreach $DIR(@DIRS) {
        if($DIR =~ /($REPO_BASE)(\/)(\w.*\.git)/) {
                print HTTP_INDEX "    <a href=\"$3\">$3</a><br>\n";
        } elsif($DIR =~ /cust/) {
                 print HTTP_INDEX "    <a href=\"cust\">Cust repos</a><br>\n";
        } elsif ($DIR =~ /index.html/) {
			next;
		} else {
                print "$DIR does not match\n";
        }
}
print HTTP_INDEX "  </body>\n</html>\n";
close(HTTP_INDEX);


