#!/usr/bin/perl 
#===============================================================================
#
#         FILE: convert_nagios_commands.pl
#
#        USAGE: ./convert_nagios_commands.pl  
#
#  DESCRIPTION: Convert nagios commands.cfg into data bags for new nagios cookbook.
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Marius Rex(MariusRex@venda.com) 
# ORGANIZATION: Venda LLC
#      VERSION: 1.0
#      CREATED: 09/05/14 14:27:40
#     REVISION: 0
#===============================================================================

use strict;
use warnings;

my $INFILE = "/etc/nagios/conf.d/commands.cfg";
my $OUTFILE;
my $NAGIOS_ID;
my $NAGIOS_COMMAND_NAME;
my $NAGIOS_COMMAND_LINE;
my $JSON_FILE;

open(NAGIOS_COMMANDS, $INFILE);
while(<NAGIOS_COMMANDS>) {
        # Swap double quotes for single quotes
        $_ =~ s/"/'/g;
        # Start of a new set
        if($_ =~ /^define command\s\{$/) {
                next;
        }
        # Grab command name
        if($_ =~ /^\s+command_name\s+(.*)$/) {
                $NAGIOS_COMMAND_NAME = $1;
                #print "Found Command name: $NAGIOS_COMMAND_NAME\n";
                if($NAGIOS_COMMAND_NAME =~ /check_(.*)/) {
                        $NAGIOS_ID = $1;
                } else {
                        $NAGIOS_ID = $NAGIOS_COMMAND_NAME;
                }
                next;
        }
        if($_ =~ /^\s+command_line\s+(.*)$/) {
                $NAGIOS_COMMAND_LINE = $1;
                #print "Found Command line: $NAGIOS_COMMAND_LINE\n\n";
                next;
        }
        if($_ =~ /^\}$/) {
                $JSON_FILE = "$NAGIOS_ID" . ".json";
                open(JSON_FILE, ">>$JSON_FILE");
                print JSON_FILE "{\n";
                print JSON_FILE "\t\"id\": \"$NAGIOS_ID\",\n";
                print JSON_FILE "\t\"hostgroup_name\": \"linux\",\n";
                print JSON_FILE "\t\"command_line\": \"$NAGIOS_COMMAND_LINE\"\n";
                print JSON_FILE "\}\n";
                close(JSON_FILE);
        }
}
