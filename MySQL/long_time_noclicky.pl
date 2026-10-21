#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## Can we figure out who has not clicked in a long time
## So we can unsubscribe them?
## Marius 2011-09-16

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

my $SUBSCRIBER;
my @SUBSCRIBER_LIST;
my $CLICK_COUNT;
my $OPEN_COUNT;
my $SUBSCRIBER_CLICK_COUNT;
my $SUBSCRIBER_NO_CLICK_COUNT;
my @PEOPLE_ID_LIST;
my @CURRENT_SUBSCRIBER_LIST;
my @NO_OPEN_6_MONTHS;
my @NO_OPEN_12_MONTHS;
my @NO_OPEN_18_MONTHS;
my @NO_OPEN_24_MONTHS;
my @NO_CLICK_6_MONTHS;
my @NO_CLICK_12_MONTHS;
my @NO_CLICK_18_MONTHS;
my @NO_CLICK_24_MONTHS;
my $TOTAL_ACTIVE_SUBSCRIBERS = "0";

# MYSQL queries and Updates.
#my $SUBSCRIBER_QUERY = "SELECT person_id FROM derived_address ORDER BY RAND() LIMIT 1000";
my $SUBSCRIBER_QUERY = "SELECT person_id FROM derived_address WHERE email LIKE '%\@gmail.com'";
my $SIX_MONTH_OPEN_QUERY = "SELECT count(person_id) FROM mailing_campaign_opens WHERE person_id = ? AND modified BETWEEN '2011-08-14 00:00:00' AND NOW()";
my $YEAR_OPEN_QUERY = "SELECT count(person_id) FROM mailing_campaign_opens WHERE person_id = ? AND modified BETWEEN '2011-02-14 00:00:00' AND '2011-08-13 23:59:59'";
my $EIGHTEEN_MONTH_OPEN_QUERY = "SELECT count(person_id) FROM mailing_campaign_opens WHERE person_id = ? AND  modified BETWEEN '2010-08-14 00:00:00' AND '2011-02-13 23:59:59'";
my $TWO_YEAR_OPEN_QUERY = "SELECT count(person_id) FROM mailing_campaign_opens WHERE person_id = ? AND modified BETWEEN '2010-02-14 00:00:00' AND '2010-08-13 23:59:59'";
my $SIX_MONTH_CLICK_QUERY = "SELECT count(person_id) FROM newsletter_deal_clicks WHERE person_id = ? AND modified BETWEEN '2011-08-14 00:00:00' AND NOW()";
my $YEAR_CLICK_QUERY = "SELECT count(person_id) FROM newsletter_deal_clicks WHERE person_id = ? AND modified BETWEEN '2011-02-14 00:00:00' AND '2011-08-13 23:59:59'"; 
my $EIGHTEEN_MONTH_CLICK_QUERY = "SELECT count(person_id) FROM newsletter_deal_clicks WHERE person_id = ? AND  modified BETWEEN '2010-08-14 00:00:00' AND '2011-02-13 23:59:59'";
my $TWO_YEAR_CLICK_QUERY = "SELECT count(person_id) FROM newsletter_deal_clicks WHERE person_id = ? AND modified BETWEEN '2010-02-14 00:00:00' AND '2010-08-13 23:59:59'";
# The table mailing_campaign_aggregates only exists on db4, and has no date fields, so I save it for last.
# Basically, "Do we have any clicks for this person_id, ever?"
my $FINAL_CLICK_QUERY = "SELECT COUNT(person_id) FROM mailing_campaign_aggregates WHERE person_id = ?";

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

# O.K.  Lets get a list of active users
print "Lets grab the list of people from derived_address.\n";
$STH = $DBH->prepare($SUBSCRIBER_QUERY);
$STH->execute() or die "Couldn't execute statement: " . $STH->errstr;
while (@PEOPLE_ID_LIST = $STH->fetchrow_array()) {
	$SUBSCRIBER = $PEOPLE_ID_LIST[0];
	push(@CURRENT_SUBSCRIBER_LIST,$SUBSCRIBER);
	#print "*";
	++$TOTAL_ACTIVE_SUBSCRIBERS;
}
print "Total Subscribers: $TOTAL_ACTIVE_SUBSCRIBERS\n";


# Now we whittle down to list and see who is left
$SUBSCRIBER_CLICK_COUNT = "0";
$SUBSCRIBER_NO_CLICK_COUNT = "0";
foreach $SUBSCRIBER(@CURRENT_SUBSCRIBER_LIST) {
	$STH = $DBH->prepare($SIX_MONTH_CLICK_QUERY);
	$STH->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $STH->errstr;
	# If we get a hit, that means they clicked, and we should remove them from our count
	# We want a list of inactive users, not active ones
	while (@PEOPLE_ID_LIST = $STH->fetchrow_array()) {
		$CLICK_COUNT = $PEOPLE_ID_LIST[0];
		if($CLICK_COUNT == "0") {
			push(@NO_CLICK_6_MONTHS,$SUBSCRIBER);
			++$SUBSCRIBER_NO_CLICK_COUNT;
			#print "$SUBSCRIBER NoClick\n";
		} else {
			++$SUBSCRIBER_CLICK_COUNT;
			#print "$SUBSCRIBER Click\n";
		}
	}
}
print "Between 2011-08-14 AND Today:\n";
print "$SUBSCRIBER_CLICK_COUNT clicking subscribers identified\n";
print "$SUBSCRIBER_NO_CLICK_COUNT subscribers had no clicks in this period.\n";
print "And of those $SUBSCRIBER_NO_CLICK_COUNT subscribers...\n";
$SUBSCRIBER_CLICK_COUNT = "0";
$SUBSCRIBER_NO_CLICK_COUNT = "0";
foreach $SUBSCRIBER(@NO_CLICK_6_MONTHS) {
	$STH = $DBH->prepare($SIX_MONTH_OPEN_QUERY);
	$STH->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $STH->errstr;
	# If we get a hit, that means they registered an 'open' in our database, and we should remove them from our count
	# We want a list of inactive users, not active ones
	while (@PEOPLE_ID_LIST = $STH->fetchrow_array()) {
		$OPEN_COUNT = $PEOPLE_ID_LIST[0];
		if($OPEN_COUNT == "0") {
			push(@NO_OPEN_6_MONTHS,$SUBSCRIBER);
			++$SUBSCRIBER_NO_CLICK_COUNT;
			#print "$SUBSCRIBER NoClick\n";
		} else {
			++$SUBSCRIBER_CLICK_COUNT;
			#print "$SUBSCRIBER Click\n";
		}
	}
}
print "$SUBSCRIBER_CLICK_COUNT subscribers opened emails\n";
print "$SUBSCRIBER_NO_CLICK_COUNT subscribers had no opens or opens for this period.\n";
print "\n\n";


$SUBSCRIBER_CLICK_COUNT = "0";
$SUBSCRIBER_NO_CLICK_COUNT = "0";
foreach $SUBSCRIBER(@NO_OPEN_6_MONTHS) {
	$STH = $DBH->prepare($YEAR_CLICK_QUERY);
	$STH->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $STH->errstr;
	# If we get a hit, that means they clicked, and we should remove them from our count
	# We want a list of inactive users, not active ones
	while (@PEOPLE_ID_LIST = $STH->fetchrow_array()) {
		$CLICK_COUNT = $PEOPLE_ID_LIST[0];
		if($CLICK_COUNT == "0") {
			push(@NO_CLICK_12_MONTHS,$SUBSCRIBER);
			++$SUBSCRIBER_NO_CLICK_COUNT
		} else {
			++$SUBSCRIBER_CLICK_COUNT;
		}		
	}
}
print "Between 2011-02-14 AND 2011-08-13:\n";
print "$SUBSCRIBER_CLICK_COUNT clicking subscribers identified\n";
print "$SUBSCRIBER_NO_CLICK_COUNT subscribers had no clicks in this period.\n";
print "And of those $SUBSCRIBER_NO_CLICK_COUNT subscribers...\n";
$SUBSCRIBER_CLICK_COUNT = "0";
$SUBSCRIBER_NO_CLICK_COUNT = "0";
foreach $SUBSCRIBER(@NO_CLICK_12_MONTHS) {
	$STH = $DBH->prepare($YEAR_OPEN_QUERY);
	$STH->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $STH->errstr;
	# If we get a hit, that means they registered an 'open' in our database, and we should remove them from our count
	# We want a list of inactive users, not active ones
	while (@PEOPLE_ID_LIST = $STH->fetchrow_array()) {
		$OPEN_COUNT = $PEOPLE_ID_LIST[0];
		if($OPEN_COUNT == "0") {
			push(@NO_OPEN_12_MONTHS,$SUBSCRIBER);
			++$SUBSCRIBER_NO_CLICK_COUNT;
			#print "$SUBSCRIBER NoClick\n";
		} else {
			++$SUBSCRIBER_CLICK_COUNT;
			#print "$SUBSCRIBER Click\n";
		}
	}
}
print "$SUBSCRIBER_CLICK_COUNT subscribers opened emails\n";
print "$SUBSCRIBER_NO_CLICK_COUNT subscribers had no opens or opens for this period.\n";
print "\n\n";


$SUBSCRIBER_CLICK_COUNT = "0";
$SUBSCRIBER_NO_CLICK_COUNT = "0";
foreach $SUBSCRIBER(@NO_OPEN_12_MONTHS) {
	$STH = $DBH->prepare($EIGHTEEN_MONTH_CLICK_QUERY);
	$STH->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $STH->errstr;
	# If we get a hit, that means they clicked, and we should remove them from our count
	# We want a list of inactive users, not active ones
	while (@PEOPLE_ID_LIST = $STH->fetchrow_array()) {
		$CLICK_COUNT = $PEOPLE_ID_LIST[0];
		if($CLICK_COUNT == "0") {
			push(@NO_CLICK_18_MONTHS,$SUBSCRIBER);
			++$SUBSCRIBER_NO_CLICK_COUNT
		} else {
			++$SUBSCRIBER_CLICK_COUNT;
		}		
	}
}
print "Between 2010-08-14 AND 2011-02-13:\n";
print "$SUBSCRIBER_CLICK_COUNT clicking subscribers identified\n";
print "$SUBSCRIBER_NO_CLICK_COUNT subscribers had no clicks in this period.\n";
print "And of those $SUBSCRIBER_NO_CLICK_COUNT subscribers...\n";
$SUBSCRIBER_CLICK_COUNT = "0";
$SUBSCRIBER_NO_CLICK_COUNT = "0";
foreach $SUBSCRIBER(@NO_CLICK_18_MONTHS) {
	$STH = $DBH->prepare($EIGHTEEN_MONTH_OPEN_QUERY);
	$STH->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $STH->errstr;
	# If we get a hit, that means they registered an 'open' in our database, and we should remove them from our count
	# We want a list of inactive users, not active ones
	while (@PEOPLE_ID_LIST = $STH->fetchrow_array()) {
		$OPEN_COUNT = $PEOPLE_ID_LIST[0];
		if($OPEN_COUNT == "0") {
			push(@NO_OPEN_18_MONTHS,$SUBSCRIBER);
			++$SUBSCRIBER_NO_CLICK_COUNT;
			#print "$SUBSCRIBER NoClick\n";
		} else {
			++$SUBSCRIBER_CLICK_COUNT;
			#print "$SUBSCRIBER Click\n";
		}
	}
}
print "$SUBSCRIBER_CLICK_COUNT subscribers opened emails\n";
print "$SUBSCRIBER_NO_CLICK_COUNT subscribers had no opens or clicks for this period.\n";
print "\n\n";

$SUBSCRIBER_CLICK_COUNT = "0";
$SUBSCRIBER_NO_CLICK_COUNT = "0";
foreach $SUBSCRIBER(@NO_OPEN_18_MONTHS) {
	$STH = $DBH->prepare($TWO_YEAR_CLICK_QUERY);
	$STH->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $STH->errstr;
	# If we get a hit, that means they clicked, and we should remove them from our count
	# We want a list of inactive users, not active ones
	while (@PEOPLE_ID_LIST = $STH->fetchrow_array()) {
		$CLICK_COUNT = $PEOPLE_ID_LIST[0];
		if($CLICK_COUNT == "0") {
			push(@NO_CLICK_24_MONTHS,$SUBSCRIBER);
			++$SUBSCRIBER_NO_CLICK_COUNT
		} else {
			++$SUBSCRIBER_CLICK_COUNT;
		}		
	}
}
print "Between 2010-02-14 AND 2010-08-13:\n";
print "$SUBSCRIBER_CLICK_COUNT clicking subscribers identified\n";
print "$SUBSCRIBER_NO_CLICK_COUNT subscribers had no clicks in this period.\n";
print "And of those $SUBSCRIBER_NO_CLICK_COUNT subscribers...\n";
$SUBSCRIBER_CLICK_COUNT = "0";
$SUBSCRIBER_NO_CLICK_COUNT = "0";
foreach $SUBSCRIBER(@NO_CLICK_24_MONTHS) {
	$STH = $DBH->prepare($TWO_YEAR_OPEN_QUERY);
	$STH->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $STH->errstr;
	# If we get a hit, that means they registered an 'open' in our database, and we should remove them from our count
	# We want a list of inactive users, not active ones
	while (@PEOPLE_ID_LIST = $STH->fetchrow_array()) {
		$OPEN_COUNT = $PEOPLE_ID_LIST[0];
		if($OPEN_COUNT == "0") {
			push(@NO_OPEN_24_MONTHS,$SUBSCRIBER);
			++$SUBSCRIBER_NO_CLICK_COUNT;
			#print "$SUBSCRIBER NoClick\n";
		} else {
			++$SUBSCRIBER_CLICK_COUNT;
			#print "$SUBSCRIBER Click\n";
		}
	}
}
print "$SUBSCRIBER_CLICK_COUNT subscribers opened emails\n";
print "$SUBSCRIBER_NO_CLICK_COUNT subscribers had no opens or clicks for this period.\n";
print "\n\n";


# And now one final attempt to rule out people
$SUBSCRIBER_CLICK_COUNT = "0";
$SUBSCRIBER_NO_CLICK_COUNT = "0";
foreach $SUBSCRIBER(@NO_OPEN_24_MONTHS) {
	$STH = $DBH->prepare($FINAL_CLICK_QUERY);
	$STH->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $STH->errstr;
	# If we get a hit, that means they clicked, and we should remove them from our count
	# We want a list of inactive users, not active ones
	while (@PEOPLE_ID_LIST = $STH->fetchrow_array()) {
		$CLICK_COUNT = $PEOPLE_ID_LIST[0];
		if($CLICK_COUNT == "0") {
			++$SUBSCRIBER_NO_CLICK_COUNT
		} else {
			++$SUBSCRIBER_CLICK_COUNT;
		}		
	}
}
print "Can we find evidence of any clicks at all in the history of the ST datbase?:\n";
print "We started with $TOTAL_ACTIVE_SUBSCRIBERS total active subscribers. Here is what we have left\n";
print "$SUBSCRIBER_CLICK_COUNT subscribers had clicks recorded in st.mailing_campaign_aggregates\n";
print "$SUBSCRIBER_NO_CLICK_COUNT subscribers seem to have no evidence of activity in the database at all.\n";
