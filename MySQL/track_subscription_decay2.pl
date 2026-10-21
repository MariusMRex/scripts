#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## Trac ticket 6712
##Discover 10,000 people who subscribed in a particular time period.
#SELECT id, source_id, person_id FROM subscriptions WHERE created BETWEEN '2010-01-01 00:00:01' AND '2010-01-15 23:59:59' ORDER BY RAND() LIMIT 10000;
# Drop data into CSV file (format through perl output)

## get listing of those who have since unsubscribed, and what date that was unsubscribed
#SELECT id, modified, unsubscribe_reason_id FROM subscriptions WHERE is_unsubscribed = "1" AND id = '?';
## Just iterate through the first list of ids and print out only those that are unsubscribed in a CSV list (Again, formatted by perl)
## Email out results


## Trac ticket 6712

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

# st.subscriptions
my $S_PERSON_ID; 				# Should match P_ID (st.people id)
my $S_SUBSCRIPTION_TYPE_ID; 	# Matches subscriptions_types id
my $S_CREATED;
my $S_MODIFIED;
my $S_IS_UNSUBSCRIBED;
my $S_UNSUBSCRIBE_REASON_ID;
my $S_SOURCE_ID;				# "External Ingestion" from st.susbscription_sources table
my $S_ID;						# Should be auto incremented.
# Variables realated to st.subscriptions, but not actually fields in the DB
my $S_CREATED_START = "$ARGV[0] 00:00:00";	# First Second of date entered at Command Line
my $S_CREATED_END = "$ARGV[1] 23:59:59";	# Last second of date entered at Command Line
# Breaking out date and time from $S_CREATED and $S_MODIFIED
my $S_CREATED_DATE;
my $S_CREATED_TIME;
my $S_MODIFIED_DATE;
my $S_MODIFIED_TIME;

# MYSQL queries and Updates.
my $SUBSCRIBER_SEARCH_QUERY = "SELECT DISTINCT person_id FROM subscriptions WHERE created BETWEEN ? AND ?";
#my $UNSUBSCRIBER_RESULTS_QUERY = "SELECT DISTINCT person_id, created, modified, subscription_type_id, unsubscribe_reason_id, is_unsubscribed FROM subscriptions WHERE is_unsubscribed = '1' AND person_id = ? GROUP BY person_id ORDER BY modified";
my $UNSUBSCRIBER_RESULTS_QUERY = "SELECT person_id, created, modified, unsubscribe_reason_id, is_unsubscribed FROM subscriptions WHERE is_unsubscribed = '1' AND person_id = ? AND created BETWEEN ? AND ? ORDER BY modified";
my @SUBSCRIBER_DATA;
my @SUBSCRIBER_PERSON_ID_LIST;
my $SUBSCRIBER_PERSON_ID;
#my @SUBSCRIPTION_TYPES = qw(US-Newsletter-Text US-Newsletter-HTML US-Bulletin UK-Newsletter-Text UK-Newsletter-HTML UK-Bulletin US-Newsletter-Text US-Newsletter-HTML US-Bulletin CheapTrips-List LuxeList American-Express-Offer Magazine-Update Pending);
my @UNSUB_REASONS = qw(Website-Unsubscribe Hard-Bounce Soft-Bounce Complaint User-Request Unknown Other Invalid-Address CEO-Request User-Cleanup);
my $SUBSCRIBER_COUNT = '0';
my $UNSUBSCRIBER_COUNT = '0';

# Open the file with the mysql password
open (FH, "$OPTIONS{db_password_file}");
flock FH,2;
$OPTIONS{mysql_password}=<FH>;
close FH;
chomp $OPTIONS{mysql_password};


# if our database handle cannot connect, spit out an error string and die
if (!($DBH = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}","$OPTIONS{db_username}","$OPTIONS{mysql_password}"))) {
    $FATAL_ERROR=1;
    $ERROR_INFO.= "DB connect error! $DBI::errstr";
    return 1;
}

# Lets Open up some log files and prep them for CSV format
open(LIST, ">>/tmp/Unsubscribed_pool_from-subscribers-$ARGV[0]-to-$ARGV[1].csv");
print LIST "User-ID,Subscription-Created-Date,Subscription-Created-Time,Last-Modified-Date,Last-Modified-Time,Unsubscribe-Reason\n";

# Choose some subscribers at 
$STH = $DBH->prepare($SUBSCRIBER_SEARCH_QUERY);
$STH->execute($S_CREATED_START, $S_CREATED_END) or die "Couldn't execute statement: " . $STH->errstr;
# put results in output file
while (@SUBSCRIBER_DATA = $STH->fetchrow_array()) {
	$S_PERSON_ID = $SUBSCRIBER_DATA[0];
	push(@SUBSCRIBER_PERSON_ID_LIST,$S_PERSON_ID);
	++$SUBSCRIBER_COUNT;
}

# Walk through subscriber list and look for unsubscribes and report them
foreach $SUBSCRIBER_PERSON_ID (@SUBSCRIBER_PERSON_ID_LIST) {
	$STH = $DBH->prepare($UNSUBSCRIBER_RESULTS_QUERY);
	$STH->execute($SUBSCRIBER_PERSON_ID,$S_CREATED_START, $S_CREATED_END) or die "Couldn't execute statement: " . $STH->errstr;

	unless ($STH->rows == 0) {
		@SUBSCRIBER_DATA = $STH->fetchrow_array();
		$S_PERSON_ID = $SUBSCRIBER_DATA[0];
		$S_CREATED = $SUBSCRIBER_DATA[1];
		$S_MODIFIED = $SUBSCRIBER_DATA[2];
		#$S_SUBSCRIPTION_TYPE_ID = $SUBSCRIBER_DATA[3];
		$S_UNSUBSCRIBE_REASON_ID = $SUBSCRIBER_DATA[3];
# Mark H. wants date and time in separate columns.
		#if($S_CREATED =~ /(\d[4]-\d?-\d?)\s(\d?:\d?:\d?)/) {
		if($S_CREATED =~ /(\d\d\d\d-\d\d-\d\d)\s(\d\d:\d\d:\d\d)/) {
			$S_CREATED_DATE = $1;
			$S_CREATED_TIME = $2;
		} else {
			$S_CREATED_DATE = 'unknown';
			$S_CREATED_TIME = 'unknown';
		}
		#if($S_MODIFIED =~ /(\d[4]-\d?-\d?)\s(\d?:\d?:\d?)/) {
		if($S_MODIFIED =~ /(\d\d\d\d-\d\d-\d\d)\s(\d\d:\d\d:\d\d)/) {
			$S_MODIFIED_DATE = $1;
			$S_MODIFIED_TIME = $2;
		} else {
			$S_MODIFIED_DATE = 'unknown';
			$S_MODIFIED_TIME = 'unknown';
		}
		#print LIST "$S_PERSON_ID,$S_CREATED_DATE,$S_CREATED_TIME,$S_MODIFIED_DATE,$S_MODIFIED_TIME,$SUBSCRIPTION_TYPES[$S_SUBSCRIPTION_TYPE_ID],$UNSUB_REASONS[$S_UNSUBSCRIBE_REASON_ID]\n";
		print LIST "$S_PERSON_ID,$S_CREATED_DATE,$S_CREATED_TIME,$S_MODIFIED_DATE,$S_MODIFIED_TIME,$UNSUB_REASONS[$S_UNSUBSCRIBE_REASON_ID]\n";
		++$UNSUBSCRIBER_COUNT;
	}
}

print LIST "Total Subscribers,$SUBSCRIBER_COUNT,Unsubscribes,$UNSUBSCRIBER_COUNT\n";
close(LIST);


