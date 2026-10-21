#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## In an attempt to root out spam traps, we removed a lot of
## addresses that were inactive got removed.  As it turns 
## out none of them were spam traps.  Because we unsubscribed
## something like 700 thousand inactive addresses, our
## numbers for sales look bad.  Mark H.  Asked me to re-subscribe
## the inactive addresses.  This script is the reverse of
## unsubscribe_by_email_list.pl
##
## in short, Mega-Maid has gone from suck to blow
##
## This script takes an augment of a CVS file to igest and process
## Current format of the files I am using is:
## $SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
##
## Marius 2011-11-03

my $DBH;                                	# Generic DB Handle
my $STH;
my $HOME = "/home/mking";
my %OPTIONS;
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "db1";          # 10.131.125.94
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
my $FATAL_ERROR;
my $ERROR_INFO;

# Variables realated to st.subscriptions, but not actually fields in the DB
my $SUBSCRIBER_LIST = $ARGV[0];			# File that contains person_ids to feed to the script Example: /home/mking/never_been_clicked.txt
#my $PERSON_ID;							# An individual email record from $EMAIL_LIST 
#my @SUBSCRIBER_DATE_ARRAY;				# Array for while loop to catch query answers
my $SUBSCRIPTION_CREATED;				# Date when subscription created
my $SUBSCRIPTION_MODIFIED;				# Date when subscription last modified
my $SUBSCRIPTION_EMAIL;					# Email address associated with person_id
my $PERSON_ID;
#my $SUBSCRIPTION_REFERRER;				# Referrer of subscription, if any
my $COUNT = "0";

## Added a row to st.unsubscribe_reasons just for this script:
## INSERT INTO unsubscribe_reasons VALUES (NULL, "Inactive Cleanup");
## st.unsubscribe Reasons
##+----+---------------------+
##| id | name                |
##+----+---------------------+
##|  1 | Website Unsubscribe |
##|  2 | Hard Bounce         |
##|  3 | Soft Bounce         |
##|  4 | Complaint           |
##|  5 | User Request        |
##|  6 | Unknown             |
##|  7 | Other               |
##|  8 | Invalid Address     |
##|  9 | CEO Request         |
##| 10 | User Cleanup        |
##| 11 | Inactive Cleanup    |
##+----+---------------------+
##

# MYSQL queries and Updates.
my $UNSUBSCRIBE_UPDATE = "UPDATE subscriptions s, people p SET s.is_unsubscribed='0', s.unsubscribe_reason_id='NULL', s.modified=NOW() WHERE p.id=s.person_id AND p.email = ?";

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

print "Opening (Inactive) Subscriber List: $SUBSCRIBER_LIST \n";
open(LIST, "$SUBSCRIBER_LIST");
while(<LIST>) {
# if our source is one of my inactive subscriber lists in csv format.
	($SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED) = split(/,/);
# if my source is just a plain file of emails.
	#$SUBSCRIPTION_EMAIL = $_;
# If our source is a list created for queue-mail
	#$SUBSCRIPTION_EMAIL,$PERSON_ID) = split(/\t/);
	chomp($SUBSCRIPTION_EMAIL);
	chomp($SUBSCRIPTION_MODIFIED);
	#print "Email is $SUBSCRIPTION_EMAIL.\n";
	print "Re-subscribing $SUBSCRIPTION_EMAIL.\n";
	$STH = $DBH->prepare($UNSUBSCRIBE_UPDATE);
	$STH->execute($SUBSCRIPTION_EMAIL) or die "Couldn't execute statement: " . $STH->errstr;
	++$COUNT;
	#sleep 1;
}
close(LIST);
print "Unsubscribed $COUNT Emails from file $SUBSCRIBER_LIST\n";
