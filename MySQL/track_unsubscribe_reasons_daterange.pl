#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## The overarching goal:
# 1. unsubs by day--I'm showing how much it's gone up lately
# 2. spam complaints (from FBL and/or other means) by day--I'm showing how much it's gone up lately
# 3. spam complaints by day or week per source, that is map the user back to the marketing referral ID (or blank if it was organic)--we want to see if specific sources cause problems but not others
# 4. for each unsub/complaint we need sub date and unsub/complaint data--we want to figure out if these are newer users or older users
# 
# #1 can hopefully be handled by  st.subscriptions.modified
# #2 Does st.unsubscribe_reasons.id '4' correspond to spam complaints?
# #3 Link back users who have st.unsubscribe_reasons.id '4' in a given date range to st.people.refer_id and ultimately st.refers st.refers.refer
# #4 link to st.susbcriptions.created as well as st.susbcriptions.modified to find out if we are dealing with old or new users.
#
# Please specify the date range on the command line

my $HOME = "/home/mking";
my $DB_Database = "st";
my $DB_Host = "10.131.125.94";          # db4 
my $DB_Username = "webuser";
my $DB_Password = "[Redacted]";
my $FATAL_ERROR;
my $ERROR_INFO;

# st.subscriptions
#my $S_PERSON_ID; 				# Should match P_ID (st.people id)
#my $S_SUBSCRIPTION_TYPE_ID; 	# Matches subscriptions_types id
#my $S_CREATED;
#my $S_MODIFIED;
#my $S_IS_UNSUBSCRIBED;
#my $S_UNSUBSCRIBE_REASON_ID;
#my $S_SOURCE_ID;				# "External Ingestion" from st.susbscription_sources table
#my $S_ID;						# Should be auto incremented.
# Variables realated to st.subscriptions, but not actually fields in the DB
my $S_CREATED_START = "$ARGV[0] 00:00:00";	# First Second of date entered at Command Line
my $S_MODIFIED_END = "$ARGV[1] 23:59:59";	# Last second of date entered at Command Line
# Breaking out date and time from $S_CREATED and $S_MODIFIED
#my $S_CREATED_DATE;
#my $S_CREATED_TIME;
#my $S_MODIFIED_DATE;
#my $S_MODIFIED_TIME;

my $SUBSCRIBER;
my @SUBSCRIBER_DATA;
#my @SUBSCRIBER_PERSON_ID_LIST;
my $COMPLAINING_UNSUBSCRIBER_PERSON_ID;
my @COMPLAINING_UNSUBSCRIBERS;
#my @UNSUB_REASONS = qw(Website-Unsubscribe Hard-Bounce Soft-Bounce Complaint User-Request Unknown Other Invalid-Address CEO-Request User-Cleanup);
#my $SUBSCRIBER_COUNT = '0';
my $UNSUBSCRIBER_DATE;
my $UNSUBSCRIBER_REFER;
my $UNSUBSCRIBER_COUNT;
my $UNSUBSCRIBER_CREATED;
my $UNSUBSCRIBER_MODIFIED;
my $UNSUBSCRIBE_REASON;

# MYSQL queries and Updates.
#my $UNSUBSCRIBE_DAILY_COUNT_QUERY = "SELECT DATE(modified) as 'Date', COUNT(*) as 'Count' FROM subscriptions WHERE modified BETWEEN DATE_SUB(CURDATE(), INTERVAL 90 DAY) AND DATE_SUB(CURDATE(), INTERVAL 0 DAY) AND is_unsubscribed = '1' AND subscription_type_id IN('2','3','9','10','11') GROUP BY DATE(modified)";
#my $UNSUBSCRIBE_COMPLAINTS_QUERY = "SELECT DATE(modified) as 'Date', COUNT(*) as 'Count' FROM subscriptions WHERE modified BETWEEN DATE_SUB(CURDATE(), INTERVAL 90 DAY) AND DATE_SUB(CURDATE(), INTERVAL 0 DAY) AND is_unsubscribed = '1' AND subscription_type_id IN('2','3','9','10','11') AND unsubscribe_reason_id = '4' GROUP BY DATE(modified)";
#my $UNSUBSCRIBE_COMPLAINTS_REASONS_QUERY = "SELECT DATE(s.modified) as 'Date', r.refer, COUNT(r.refer) as 'Count' FROM subscriptions as s, people as p, refers as r WHERE s.modified BETWEEN DATE_SUB(CURDATE(), INTERVAL 90 DAY) AND DATE_SUB(CURDATE(), INTERVAL 0 DAY) AND s.is_unsubscribed = '1' AND s.subscription_type_id IN('2','3','9','10','11') AND s.unsubscribe_reason_id = '4' AND s.person_id = p.id AND p.refer_id = r.id GROUP BY DATE(s.modified), r.refer";
#my $UNSUBSCRIBE_COMPLAINTS_DATE_QUERY = "SELECT DISTINCT person_id, created, modified FROM subscriptions WHERE modified BETWEEN DATE_SUB(CURDATE(), INTERVAL 90 DAY) AND DATE_SUB(CURDATE(), INTERVAL 0 DAY) AND is_unsubscribed = '1' AND subscription_type_id IN('2','3','9','10','11') AND unsubscribe_reason_id = '4'";

my $UNSUBSCRIBE_DAILY_COUNT_QUERY = "SELECT DATE(modified) as 'Date', COUNT(*) as 'Count' FROM subscriptions WHERE modified BETWEEN DATE_SUB(?, INTERVAL 1 DAY) AND ? AND is_unsubscribed = '1' AND subscription_type_id IN('2','3','9','10','11') GROUP BY DATE(modified)";
my $UNSUBSCRIBE_COMPLAINTS_QUERY = "SELECT DATE(modified) as 'Date', COUNT(*) as 'Count' FROM subscriptions WHERE modified BETWEEN DATE_SUB(?, INTERVAL 1 DAY) AND ? AND is_unsubscribed = '1' AND subscription_type_id IN('2','3','9','10','11') AND unsubscribe_reason_id = '4' GROUP BY DATE(modified)";
my $UNSUBSCRIBE_COMPLAINTS_REASONS_QUERY = "SELECT DATE(s.modified) as 'Date', r.refer, COUNT(r.refer) as 'Count' FROM subscriptions as s, people as p, refers as r WHERE s.modified BETWEEN DATE_SUB(?, INTERVAL 1 DAY) AND ? AND s.is_unsubscribed = '1' AND s.subscription_type_id IN('2','3','9','10','11') AND s.unsubscribe_reason_id = '4' AND s.person_id = p.id AND p.refer_id = r.id GROUP BY DATE(s.modified), r.refer";
my $UNSUBSCRIBE_COMPLAINTS_DATE_QUERY = "SELECT DISTINCT person_id, created, modified FROM subscriptions WHERE modified BETWEEN DATE_SUB(?, INTERVAL 1 DAY) AND ? AND is_unsubscribed = '1' AND subscription_type_id IN('2','3','9','10','11') AND unsubscribe_reason_id = '4'";
my $NINETY_DAY_UNSUB_REASONS_AND_REFER_QUERY = "SELECT DISTINCT s.person_id, s.created, s.modified, r.refer, ur.name FROM subscriptions AS s, people as p, refers as r, unsubscribe_reasons as ur WHERE s.modified BETWEEN DATE_SUB(?, INTERVAL 1 DAY) AND ? AND s.is_unsubscribed = '1' AND s.subscription_type_id IN('2','3','9','10','11') AND s.person_id = p.id AND p.refer_id = r.id AND ur.id = s.unsubscribe_reason_id";

my $dbh=DBI->connect("DBI:mysql:host=$DB_Host;database=$DB_Database","$DB_Username", "$DB_Password", {PrintError=>0, RaiseError=>0})
	or
	die("Failed connecting to Db4 ". "(error number $DBI::err): $DBI::errstr\n"); 


# File to track recent unsubscribe requests
open(RECENT_UNSUBS, ">/tmp/spamhaus/Unsubscribed_daily_$ARGV[0]-$ARGV[1].csv");
print RECENT_UNSUBS "Unsubscribe requests by date,90 day period\n";
print RECENT_UNSUBS "Date,Count\n";

my $sth = $dbh->prepare($UNSUBSCRIBE_DAILY_COUNT_QUERY);
$sth->execute($S_CREATED_START,$S_MODIFIED_END) or die "Couldn't execute statement: " . $sth->errstr;
while (@SUBSCRIBER_DATA = $sth->fetchrow_array()) {
	$UNSUBSCRIBER_DATE = $SUBSCRIBER_DATA[0];
	$UNSUBSCRIBER_COUNT = $SUBSCRIBER_DATA[1];
	print RECENT_UNSUBS "$UNSUBSCRIBER_DATE,$UNSUBSCRIBER_COUNT\n";
}
close(RECENT_UNSUBS);

# File to track recent unsubscribe requests due to user complaints
open(UNSUBS_COMPLAINTS, ">/tmp/spamhaus/complaints_daily_$ARGV[0]-$ARGV[1].csv");
print UNSUBS_COMPLAINTS "Complaints by date,90 day period\n";
print UNSUBS_COMPLAINTS "Date,Count\n";

$sth = $dbh->prepare($UNSUBSCRIBE_COMPLAINTS_QUERY);
$sth->execute($S_CREATED_START,$S_MODIFIED_END) or die "Couldn't execute statement: " . $sth->errstr;
while (@SUBSCRIBER_DATA = $sth->fetchrow_array()) {
	$UNSUBSCRIBER_DATE = $SUBSCRIBER_DATA[0];
	$UNSUBSCRIBER_COUNT = $SUBSCRIBER_DATA[1];
	print UNSUBS_COMPLAINTS "$UNSUBSCRIBER_DATE,$UNSUBSCRIBER_COUNT\n";
}
close(UNSUBS_COMPLAINTS);

# File to track recent unsubscribe requests due to user complaints
open(UNSUBS_REFERS, ">/tmp/spamhaus/complaints_refers_daily_$ARGV[0]-$ARGV[1].csv");
print UNSUBS_REFERS "Spam complaint Reasons,90 day period,\n";
print UNSUBS_REFERS "Date,Source,Count,\n";

$sth = $dbh->prepare($UNSUBSCRIBE_COMPLAINTS_REASONS_QUERY);
$sth->execute($S_CREATED_START,$S_MODIFIED_END) or die "Couldn't execute statement: " . $sth->errstr;
while (@SUBSCRIBER_DATA = $sth->fetchrow_array()) {
	$UNSUBSCRIBER_DATE = $SUBSCRIBER_DATA[0];
	$UNSUBSCRIBER_REFER = $SUBSCRIBER_DATA[1];
	$UNSUBSCRIBER_COUNT = $SUBSCRIBER_DATA[2];
	print UNSUBS_REFERS "$UNSUBSCRIBER_DATE,$UNSUBSCRIBER_REFER,$UNSUBSCRIBER_COUNT\n";
}
close(UNSUBS_REFERS);


# File to track recent unsubscribe requests due to user complaints
open(UNSUBS_DATE, ">/tmp/spamhaus/complaints_sub_unsub_date_$ARGV[0]-$ARGV[1].csv");
print UNSUBS_DATE "Spam complaint Subscribe and unsubscribe dates,90 day period,\n";
print UNSUBS_DATE "Person ID,Created,Unsubscribed\n";

$sth = $dbh->prepare($UNSUBSCRIBE_COMPLAINTS_DATE_QUERY);
$sth->execute($S_CREATED_START,$S_MODIFIED_END) or die "Couldn't execute statement: " . $sth->errstr;
while (@SUBSCRIBER_DATA = $sth->fetchrow_array()) {
	$COMPLAINING_UNSUBSCRIBER_PERSON_ID = $SUBSCRIBER_DATA[0];
	$UNSUBSCRIBER_CREATED = $SUBSCRIBER_DATA[1];
	$UNSUBSCRIBER_MODIFIED = $SUBSCRIBER_DATA[2];
	print UNSUBS_DATE "$COMPLAINING_UNSUBSCRIBER_PERSON_ID,$UNSUBSCRIBER_CREATED,$UNSUBSCRIBER_MODIFIED\n";
}
close(UNSUBS_DATE);
	

# File to track recent unsubscribe requests due to user complaints
open(UNSUBS_PROFILE, ">/tmp/spamhaus/unsubscriber_data_$ARGV[0]-$ARGV[1].csv");
print UNSUBS_PROFILE "Profile of unsusbscrivers,90 day period,\n";
print UNSUBS_PROFILE "Person ID,Created,Unsubscribed,source,Unsubscribe Reason\n";

$sth = $dbh->prepare($NINETY_DAY_UNSUB_REASONS_AND_REFER_QUERY);
$sth->execute($S_CREATED_START,$S_MODIFIED_END) or die "Couldn't execute statement: " . $sth->errstr;
while (@SUBSCRIBER_DATA = $sth->fetchrow_array()) {
	$COMPLAINING_UNSUBSCRIBER_PERSON_ID = $SUBSCRIBER_DATA[0];
	$UNSUBSCRIBER_CREATED = $SUBSCRIBER_DATA[1];
	$UNSUBSCRIBER_MODIFIED = $SUBSCRIBER_DATA[2];
	$UNSUBSCRIBER_REFER = $SUBSCRIBER_DATA[3];
	$UNSUBSCRIBE_REASON = $SUBSCRIBER_DATA[4];
	print UNSUBS_PROFILE "$COMPLAINING_UNSUBSCRIBER_PERSON_ID,$UNSUBSCRIBER_CREATED,$UNSUBSCRIBER_MODIFIED,$UNSUBSCRIBER_REFER,$UNSUBSCRIBE_REASON\n";
}
close(UNSUBS_PROFILE);

$sth->finish();
$dbh->disconnect();

