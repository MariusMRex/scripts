#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## Quick script to find the subscription date from a list of 
## person_ids.  I am using this is conjunction with
## long_time_no_clicky.pl to try to find spam traps
##
## The only table needed here is st.people, as all
## The heavy lifting has been done by other scripts
## and I alreay have an file full of person_ids
##
## This script takes a file of person_ids, one per line, 
## and outputs a cvs file for import into a spreadsheet
##
## Marius 2011-09-27

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
my $PERSON_ID_LIST = $ARGV[0];			# File that contains person_ids to feed to the script Example: /home/mking/never_been_clicked.txt
my $PERSON_ID;							# An individual email record from $EMAIL_LIST 
my @SUBSCRIBER_DATE_ARRAY;				# Array for while loop to catch query answers
my $SUBSCRIPTION_CREATED;				# Date when subscription created
my $SUBSCRIPTION_MODIFIED;				# Date when subscription last modified
my $SUBSCRIPTION_EMAIL;					# Email address associated with person_id
#my $SUBSCRIPTION_REFERRER;				# Referrer of subscription, if any

# Date ranges to divvy up subscribers, since we have so many
my $COUNT = "0";
my $BEGIN_DATE;
my @BDATE = ("0000-00-00 00:00:00","2004-01-01 00:00:00","2004-07-01 00:00:00","2005-01-01 00:00:00","2005-07-01 00:00:00","2006-01-01 00:00:00","2006-07-01 00:00:00","2007-01-01 00:00:00","2007-07-01 00:00:00","2008-01-01 00:00:00","2008-07-01 00:00:00","2009-01-01 00:00:00","2009-07-01 00:00:00","2010-01-01 00:00:00","2010-07-01 00:00:00","2011-01-01 00:00:00","2011-07-01 00:00:00");
my $END_DATE;
my @EDATE = ("2003-12-31 23:59:59","2004-06-31 23:59:59","2004-12-31 23:59:59","2005-06-31 23:59:59","2005-12-31 23:59:59","2006-06-31 23:59:59","2006-12-31 23:59:59","2007-06-31 23:59:59","2007-12-31 23:59:59","2008-06-31 23:59:59","2008-12-31 23:59:59","2009-06-31 23:59:59","2009-12-31 23:59:59","2010-06-31 23:59:59","2010-12-31 23:59:59","2011-06-31 23:59:59","2011-12-31 23:59:59");

# MYSQL queries and Updates.
my $SUBSCRIBER_SEARCH_QUERY = "SELECT r.refer FROM people AS p, refers AS r WHERE p.email = ? AND r.id = p.refer_id;";
my $SUBSCRIBER_SEARCH_QUERY_BY_DATE = "SELECT email, created, modified FROM people WHERE id = ? AND created BETWEEN ? AND ?";

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

# Lets save our reults to a text file
#open(CREATED, ">>inactive_subscriber_creation_date.csv");
open(CREATED0, ">>inactive_subscriber_date_unknown.csv");
open(CREATED1, ">>inactive_subscriber_2004_p1.csv");
open(CREATED2, ">>inactive_subscriber_2004_p2.csv");
open(CREATED3, ">>inactive_subscriber_2005_p1.csv");
open(CREATED4, ">>inactive_subscriber_2005_p2.csv");
open(CREATED5, ">>inactive_subscriber_2006_p1.csv");
open(CREATED6, ">>inactive_subscriber_2006_p2.csv");
open(CREATED7, ">>inactive_subscriber_2007_p1.csv");
open(CREATED8, ">>inactive_subscriber_2007_p2.csv");
open(CREATED9, ">>inactive_subscriber_2008_p1.csv");
open(CREATED10, ">>inactive_subscriber_2008_p2.csv");
open(CREATED11, ">>inactive_subscriber_2009_p1.csv");
open(CREATED12, ">>inactive_subscriber_2009_p2.csv");
open(CREATED13, ">>inactive_subscriber_2010_p1.csv");
open(CREATED14, ">>inactive_subscriber_2010_p2.csv");
open(CREATED15, ">>inactive_subscriber_2011_p1.csv");
open(CREATED16, ">>inactive_subscriber_2011_p2.csv");
open(PROBLEM_CHILD, ">>inactive_subscriber_problem_child.csv");

print "Opening person_id list\n";
open(LIST, "$PERSON_ID_LIST");
UNIQUEPID: while(<LIST>) {
	$PERSON_ID = $_;
	chomp($PERSON_ID);
	#print "person_id is $PERSON_ID.\n";
	while($COUNT <= "16") {
		$BEGIN_DATE = "$BDATE[$COUNT]";
		$END_DATE = "$EDATE[$COUNT]";
		#print "Query on $BEGIN_DATE to $END_DATE\n";
		$STH = $DBH->prepare($SUBSCRIBER_SEARCH_QUERY_BY_DATE);
		$STH->execute($PERSON_ID,$BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
		unless ($STH->rows == 0) {
			while (@SUBSCRIBER_DATE_ARRAY = $STH->fetchrow_array()) {
				$SUBSCRIPTION_EMAIL = $SUBSCRIBER_DATE_ARRAY[0];
				$SUBSCRIPTION_CREATED = $SUBSCRIBER_DATE_ARRAY[1];
				$SUBSCRIPTION_MODIFIED = $SUBSCRIBER_DATE_ARRAY[2];
				if($SUBSCRIPTION_EMAIL =~ /.*\@shermanstravelmedia.com/) {
					print "Skipping $SUBSCRIPTION_EMAIL\n";
					next UNIQUEPID;
				} elsif($COUNT == "0") {
					print CREATED0 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "1") {
					print CREATED1 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "2") {
					print CREATED2 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "3") {
					print CREATED3 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "4") {
					print CREATED4 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "5") {
					print CREATED5 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "6") {
					print CREATED6 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "7") {
					print CREATED7 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "8") {
					print CREATED8 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "9") {
					print CREATED9 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "10") {
					print CREATED10 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "11") {
					print CREATED11 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "12") {
					print CREATED12 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "13") {
					print CREATED13 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "14") {
					print CREATED14 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "15") {
					print CREATED15 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} elsif($COUNT == "16") {
					print CREATED16 "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				} else {
					print PROBLEM_CHILD "$SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
					next UNIQUEPID;
				}
			}
		}
		++$COUNT
	}
# Reset Counter
	$COUNT = "0"
}
close(LIST);
close(CREATED0);
close(CREATED1);
close(CREATED2);
close(CREATED3);
close(CREATED4);
close(CREATED5);
close(CREATED6);
close(CREATED7);
close(CREATED8);
close(CREATED9);
close(CREATED10);
close(CREATED11);
close(CREATED12);
close(CREATED13);
close(CREATED14);
close(CREATED15);
close(CREATED16);
close(PROBLEM_CHILD);
print "Writing out results inactive_subscriber_2004-2011.csv\n";
