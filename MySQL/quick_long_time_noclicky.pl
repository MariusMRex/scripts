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
my $TOTAL_ACTIVE_SUBSCRIBERS = "0";

# MYSQL queries and Updates.
#my $SUBSCRIBER_QUERY = "SELECT person_id FROM derived_address ORDER BY RAND() LIMIT 1000";
my $SUBSCRIBER_QUERY = "SELECT person_id FROM derived_address";
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
print "\n";

open("NO_CLICKERS", ">/home/mking/never_been_clicked.txt");
# the normal long_time_no_clicky.pl takes a long time to run
# and returns a list of people who have never clicked at all.
# What if we only did one query per user?
$SUBSCRIBER_CLICK_COUNT = "0";
$SUBSCRIBER_NO_CLICK_COUNT = "0";
foreach $SUBSCRIBER(@CURRENT_SUBSCRIBER_LIST) {
	$STH = $DBH->prepare($FINAL_CLICK_QUERY);
	$STH->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $STH->errstr;
	# If we get a hit, that means they clicked, and we should remove them from our count
	# We want a list of inactive users, not active ones
	while (@PEOPLE_ID_LIST = $STH->fetchrow_array()) {
		$CLICK_COUNT = $PEOPLE_ID_LIST[0];
		if($CLICK_COUNT == "0") {
			++$SUBSCRIBER_NO_CLICK_COUNT;
			print NO_CLICKERS "$SUBSCRIBER\n";
		} else {
			++$SUBSCRIBER_CLICK_COUNT;
		}		
	}
}
close(NO_CLICKERS);
print "Can we find evidence of any clicks at all in the history of the ST datbase?:\n";
print "We started with $TOTAL_ACTIVE_SUBSCRIBERS total active subscribers. Here is what we have left\n";
print "$SUBSCRIBER_CLICK_COUNT subscribers had clicks recorded in st.mailing_campaign_aggregates\n";
print "$SUBSCRIBER_NO_CLICK_COUNT subscribers seem to have no evidence of activity in the database at all.\n";
