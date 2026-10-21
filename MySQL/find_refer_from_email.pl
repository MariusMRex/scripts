#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## Quick script to find the referrers that brought us a particular email.
## When I see a long list of unsubscribe requests I might want
## to know who the referrer is to check quality of our partners.
##
## This script takes a file of email addresses, one per line, 
## much like I might copy from the daily unsubscribe email.
##
## The reults are unformatted and sent to the terminal, but can
## easily be piped through sort or uniq
## Marius 2011-09-14

my $DBH;                                	# Generic DB Handle
my $STH;
my $HOME = "/home/mking";
my %OPTIONS;
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "db4";          # 10.131.125.94
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
my $FATAL_ERROR;
my $ERROR_INFO;

# Variables realated to st.subscriptions, but not actually fields in the DB
my $EMAIL_LIST = $ARGV[0];				# File that contains email addresses to feed to the script
my $SUBSCRIBER;							# An individual email record from $EMAIL_LIST 
my @SUBSCRIBER_REFERER;					# Array for while loop to catch query answers
my $SUBSCRIPTION_SOURCE;				# Referrer reported by script, data comes from @SUBSCRIBER_REFERER

# MYSQL queries and Updates.
my $SUBSCRIBER_SEARCH_QUERY = "SELECT r.refer FROM people AS p, refers AS r WHERE p.email = ? AND r.id = p.refer_id;";

print "Grabbing password file\n";
# Open the file with the mysql password
open (FH, "$OPTIONS{db_password_file}");
flock FH,2;
$OPTIONS{mysql_password}=<FH>;
close FH;
chomp $OPTIONS{mysql_password};

print "Initiating database connection.\n";
# if our database handle cannot connect, spit out an error string and die
if (!($DBH = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}","$OPTIONS{db_username}","$OPTIONS{mysql_password}"))) {
    $FATAL_ERROR=1;
    $ERROR_INFO.= "DB connect error! $DBI::errstr";
    return 1;
}

print "Opening email list\n";
open(LIST, "$EMAIL_LIST");
while(<LIST>) {
	$SUBSCRIBER = $_;
	chomp($SUBSCRIBER);
	#print "Subscriber is $SUBSCRIBER :";
	$STH = $DBH->prepare($SUBSCRIBER_SEARCH_QUERY);
	$STH->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $STH->errstr;
## print results
	#print "...";
	while (@SUBSCRIBER_REFERER = $STH->fetchrow_array()) {
		$SUBSCRIPTION_SOURCE = $SUBSCRIBER_REFERER[0];
		#print "Source of Subscriber: $SUBSCRIPTION_SOURCE\n";
		print "$SUBSCRIPTION_SOURCE\n";
	}
}
close(LIST);
