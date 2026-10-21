#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## This script takes a list fo emails and then unsubscribes 
## them from active use.  With small tweaks it can accept
## email lists, csv lists, and the files I feed to mail-queue
##
## CSV format
## $SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED\n";
##
## I am currently using this is conjunction with
## long_time_no_clicky.pl to try to find spam traps
## Marius 2011-10-05
##
## We no longer use MMW, we need to use stsite-mysqldb02 for people data
## We should also INSERT some rows into the actions table 
## Marius 2012-05-08
## 
## This script should now detect the major subscription types that a user has
## and add appropriate rows to the st.actions table to match the updates to the
## st.subscriptions table.
## Marius 2012-05-10

my $dbh;                                	# Generic DB Handle
my $sth;
my $HOME = "/home/mking";
my %OPTIONS;
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "stsite-db";          # For wring to the master stsite DB
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
my $SUBSCRIPTION_TYPE_ID;				# Type of subscription
my $PERSON_ID;
#my $SUBSCRIPTION_REFERRER;				# Referrer of subscription, if any
my $COUNT = "0";
my @SUBSCRIBER_DATA;
my $SUBSCRIBED_BULLETIN = '0';				# User subscribed to Bulletin
my $SUBSCRIBED_TOP25 = '0';					# User subscribed to Top25
my $SUBSCRIBED_LUX = '0';						# User subscribed to Lux list (depreciated)

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
##mysql> DESC actions;
##+------------------------+------------------+------+-----+---------+----------------+
##| Field                  | Type             | Null | Key | Default | Extra          |
##+------------------------+------------------+------+-----+---------+----------------+
##| id                     | int(10) unsigned | NO   | PRI | NULL    | auto_increment | 
##| visit_id               | int(10) unsigned | YES  |     | NULL    |                | 
##| action_type_id         | int(10) unsigned | YES  |     | NULL    |                | 
##| created                | datetime         | YES  | MUL | NULL    |                | 
##| subscription_source_id | int(11)          | YES  |     | NULL    |                | 
##| subscriber_type_id     | int(11)          | YES  |     | NULL    |                | 
##| person_id              | int(11)          | YES  | MUL | NULL    |                | 
##+------------------------+------------------+------+-----+---------+----------------+
##
## mysql> SELECT * FROM action_types;
##+----+-------------------------+
##| id | name                    |
##+----+-------------------------+
##|  5 | Bulletin Signup         | 
##| 12 | Bulletin Supress        | 
##|  6 | Bulletin Unsubscribe    | 
##|  3 | Luxe15 Signup           | 
##| 14 | Luxe15 Supress          | 
##|  4 | Luxe15 Unsubscribe      | 
##|  7 | Magazine Subscription   | 
##|  8 | Preferences Accessed    | 
##|  9 | Preferences Modified    | 
##| 10 | Special Interest Add    | 
##| 11 | Special Interest Remove | 
##|  1 | Top25 Signup            | 
##| 13 | Top25 Supress           | 
##|  2 | Top25 Unsubscribe       | 
##+----+-------------------------+

# MYSQL queries and Updates.
my $SUBSCRIPTION_QUERY = "SELECT subscription_type_id FROM subscriptions WHERE person_id = ? AND is_unsubscribed != '1'";
my $UNSUBSCRIBE_UPDATE = "UPDATE subscriptions s, people p SET s.is_unsubscribed='1', s.unsubscribe_reason_id='11', s.modified=NOW() WHERE p.id=s.person_id AND p.email = ?";
my $ACTIONS_INSERT_TOP25 = "INSERT INTO actions VALUES (NULL, NULL, 2, NOW(), NULL, NULL, ?)";
my $ACTIONS_INSERT_BULLETIN = "INSERT INTO actions VALUES (NULL, NULL, 6, NOW(), NULL, NULL, ?)";
my $ACTIONS_INSERT_LUX = "INSERT INTO actions VALUES (NULL, NULL, 4, NOW(), NULL, NULL, ?)";

print "Grabbing password file\n";
# Open the file with the mysql password
open (FH, "$OPTIONS{db_password_file}");
flock FH,2;
my $MYSQL_PASSWORD=<FH>;
close FH;
chomp $MYSQL_PASSWORD;

print "Initiating database connection.\n";
$dbh = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}",$OPTIONS{db_username},$MYSQL_PASSWORD, {RaiseError => 1}); 

print "Opening (Inactive) Subscriber List: $SUBSCRIBER_LIST \n";
open(LIST, "$SUBSCRIBER_LIST");
while(<LIST>) {
# if our source is one of my inactive subscriber lists in csv format.
	#($SUBSCRIPTION_EMAIL,$SUBSCRIPTION_CREATED,$SUBSCRIPTION_MODIFIED) = split(/,/);
# if my source is just a plain file of emails.
	#$SUBSCRIPTION_EMAIL = $_;
# If our source is a list created for queue-mail
	($SUBSCRIPTION_EMAIL,$PERSON_ID) = split(/\t/);
	chomp($SUBSCRIPTION_EMAIL);
	chomp($PERSON_ID);
	#chomp($SUBSCRIPTION_MODIFIED);
	#print "Email is $SUBSCRIPTION_EMAIL.\n";
#
# Now lets see what subscriptions we find and update as seems appropriate.
	$sth = $dbh->prepare($SUBSCRIPTION_QUERY);
	$sth->execute($PERSON_ID) or die "Couldn't execute statement: " . $sth->errstr;
	while (@SUBSCRIBER_DATA = $sth->fetchrow_array()) {
		if($sth->rows == 0) {
			print "Nothing to do for $PERSON_ID\n";
			last;
		} else {
			$SUBSCRIPTION_TYPE_ID = $SUBSCRIBER_DATA[0];
			if($SUBSCRIPTION_TYPE_ID =~ /1|2|5|6|9|10/) {
				print "Found top25 subscription\n";
				$SUBSCRIBED_TOP25 = "1"; 
			}
			if($SUBSCRIPTION_TYPE_ID =~ /3|7|11/) {
				print "Found bulletin subscription\n";
				$SUBSCRIBED_BULLETIN = "1";
			}
			if($SUBSCRIPTION_TYPE_ID == "100") {
				print "Found lux subscription\n";
				$SUBSCRIBED_LUX = "1"; 
			}
		}
	}
	print "Unsubscribing $SUBSCRIPTION_EMAIL.\n";
	$sth = $dbh->prepare($UNSUBSCRIBE_UPDATE);
	$sth->execute($SUBSCRIPTION_EMAIL) or die "Couldn't execute statement: " . $sth->errstr;
	if($SUBSCRIBED_TOP25 == "1") {
		$sth = $dbh->prepare($ACTIONS_INSERT_TOP25);
		$sth->execute($PERSON_ID) or die "Couldn't execute statement: " . $sth->errstr;
		print "--recording unsubscribe to top25\n";
# reset subscription types
		$SUBSCRIBED_TOP25 = "0";
	}
	if($SUBSCRIBED_BULLETIN == "1") {
		$sth = $dbh->prepare($ACTIONS_INSERT_BULLETIN);
		$sth->execute($PERSON_ID) or die "Couldn't execute statement: " . $sth->errstr;
		print "--recording unsubscribe to bulletins\n";
# reset subscription types
		$SUBSCRIBED_BULLETIN = "0";
	}
	if($SUBSCRIBED_LUX == "1") {
		$sth = $dbh->prepare($ACTIONS_INSERT_LUX);
		$sth->execute($PERSON_ID) or die "Couldn't execute statement: " . $sth->errstr;
		print "--recording unsubscribe to Lux list\n";
# reset subscription types
		$SUBSCRIBED_LUX = "0";
	}
# Count one email as processed
	++$COUNT;
	#sleep 1;
}
close(LIST);
print "Unsubscribed $COUNT Emails from file $SUBSCRIBER_LIST\n";


# Finally close out our DB connections
$sth->finish();
$dbh->disconnect();

