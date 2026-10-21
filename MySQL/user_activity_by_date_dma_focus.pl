#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## Current Request: 2012-03-08
## Jim has asked for the counts of our active users, to aid in making the decision of how many to scrub. Can you please provide me with the following info:
##
## Active (opened or clicked) within the last 1.5 years:
## Active (opened or clicked) within the last 2 years: 
## Active (opened or clicked) within the last 3 years: 
## Total subscriber count as of the time you ran these queries (so I can extrapolate how many names would be scrubbed):

## user_activity_by_date_dma_focus.pl is basically user_activity_by_date.pl with a few tweaks to 
## drill down to a particular DMA Marius 03/09/2012

my $dbh;                                	# Generic DB Handle
my $sth;
my $HOME = "/home/mking";
my $DMA = "803"; 	# LA
my $MAIL_FILES_HOME = "/home/mking/marii_bin/mailfiles/$DMA";
my %OPTIONS;
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "db4";          # 10.131.125.94
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
my $FATAL_ERROR;
my $ERROR_INFO;

my $SUBSCRIBER;
my @SUBSCRIBER_LIST;
my $SUBSCRIPTION_DATE;
#my $PERSON_ID;
my $EMAIL;
my @PEOPLE_LIST;
my @CURRENT_SUBSCRIBER_LIST;
my @NO_CLICK_RECENT;
my @NO_OPEN_RECENT;
my @NO_CLICK_P2;
my @NO_OPEN_P2;
my @NO_CLICK_P3;
my @NO_OPEN_P3;
my $SUBSCRIPTION_YEAR;
my $TOTAL_ACTIVE_SUBSCRIBERS = "0";
my $LOST_COUNT = "0";

# MYSQL queries and Updates.
my $SUBSCRIBER_QUERY = "SELECT person_id FROM derived_address WHERE derived_dma = ? AND (email NOT IN (SELECT email FROM suppression_recent_subs_2011_02_02)) AND (email NOT IN(SELECT email FROM possible_spam_traps_2011_11_04))";  
# Clicked in the last 1.5 years
my $RECENT_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2010-09-08 00:00:00' AND NOW() LIMIT 1";
my $RECENT_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2010-09-08 00:00:00' AND NOW() LIMIT 1";
# P2 2 years
my $P2_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2010-03-08 00:00:00' AND '2010-09-07 23:59:59' LIMIT 1";
my $P2_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2010-03-08 00:00:00' AND '2010-09-07 23:59:59' LIMIT 1";
# P2 3 years
my $P3_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2009-03-08 00:00:00' AND '2010-03-07 23:59:59' LIMIT 1"; 
my $P3_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2009-03-08 00:00:00' AND '2010-03-07 23:59:59' LIMIT 1";
# We have no click or open data from before August of 2009
my $NOT_ACTIVE_QUERY = "SELECT email FROM people WHERE id = ?";

print "Grabbing password file\n";
# Open the file with the mysql password
open (FH, "$OPTIONS{db_password_file}");
flock FH,2;
$OPTIONS{mysql_password}=<FH>;
close FH;
chomp $OPTIONS{mysql_password};

print "Initiating database connection.\n";
# if our database handle cannot connect, spit out an error string and die
if (!($dbh = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}","$OPTIONS{db_username}","$OPTIONS{mysql_password}"))) {
    $FATAL_ERROR=1;
    $ERROR_INFO.= "DB connect error! $DBI::errstr";
    return 1;
}

# O.K.  Lets get a list of active users
print "Lets grab the list of people from derived_address from dma $DMA, filtering out suspected spam trap list\n";
$sth = $dbh->prepare($SUBSCRIBER_QUERY);
$sth->execute($DMA) or die "Couldn't execute statement: " . $sth->errstr;
while (@PEOPLE_LIST = $sth->fetchrow_array()) {
	$SUBSCRIBER = $PEOPLE_LIST[0];
	push(@CURRENT_SUBSCRIBER_LIST,$SUBSCRIBER);
	#print "*";
	++$TOTAL_ACTIVE_SUBSCRIBERS;
}
print "Total Active Subscribers Found: $TOTAL_ACTIVE_SUBSCRIBERS\n";

# Lets create a directory, to stick mail files into, if it does not already exist
unless(-d "$MAIL_FILES_HOME") {
	print "Making $MAIL_FILES_HOME for storage of mail files.\n";
	mkdir("$MAIL_FILES_HOME",0777) || die "Cannot mkdir $MAIL_FILES_HOME: $!";
}
# Lets open some mail files for writing to in our special directory
open(RECENT, ">$MAIL_FILES_HOME/within_18months.txt");
open(P2, ">$MAIL_FILES_HOME/two_years.txt");
open(P3, ">$MAIL_FILES_HOME/three_years.txt");
open(DEADBEATS, ">$MAIL_FILES_HOME/no-activity.txt");

my $RECENT_COUNT = "0";
my $P2_COUNT = "0";
my $P3_COUNT = "0";
my $DEADBEATS_COUNT = "0";

print "Looking for recent clicks\n";
foreach $SUBSCRIBER(@CURRENT_SUBSCRIBER_LIST) {
	#print "Subscriber is $SUBSCRIBER\n";
	$sth = $dbh->prepare($RECENT_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they clicked, so we will put them in the mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_RECENT,$SUBSCRIBER);
	} else {
		print RECENT "$EMAIL\t$SUBSCRIBER\n";
		++$RECENT_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for recent opens\n";   # Within the last 18 months
foreach $SUBSCRIBER(@NO_CLICK_RECENT) {
	$sth = $dbh->prepare($RECENT_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_RECENT,$SUBSCRIBER);
	} else {
		print RECENT "$EMAIL\t$SUBSCRIBER\n";
		++$RECENT_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}

# interaction in last two years
print "Looking for clicks P2 (Two Years)\n";
foreach $SUBSCRIBER(@NO_OPEN_RECENT) {
	$sth = $dbh->prepare($P2_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P2,$SUBSCRIBER);
	} else {
		print P2 "$EMAIL\t$SUBSCRIBER\n";
		++$P2_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for opens in P2 (Two Years)\n";
foreach $SUBSCRIBER(@NO_CLICK_P2) {
	$sth = $dbh->prepare($P2_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P2,$SUBSCRIBER);
	} else {
		print P2 "$EMAIL\t$SUBSCRIBER\n";
		++$P2_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}


# interaction in P3 (Three Years)
print "Looking for clicks p3 (Three Years)\n";
foreach $SUBSCRIBER(@NO_OPEN_P2) {
	$sth = $dbh->prepare($P3_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P3,$SUBSCRIBER);
	} else {
		print P3 "$EMAIL\t$SUBSCRIBER\n";
		++$P3_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for opens 2010 p3 (Three Years)\n";
foreach $SUBSCRIBER(@NO_CLICK_P3) {
	$sth = $dbh->prepare($P3_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P3,$SUBSCRIBER);
	} else {
		print P3 "$EMAIL\t$SUBSCRIBER\n";
		++$P3_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}

# All that is left is people who do not seem to click or open
print "And now the folks who do not interact at all it seems within the stated periods\n";
foreach $SUBSCRIBER(@NO_OPEN_P3) {
	$sth = $dbh->prepare($NOT_ACTIVE_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
# Any ids we have left appearently did not have any clicks or opens we could find.
# Lets give them their own mailfile.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		++$LOST_COUNT;
	} else {
		print DEADBEATS "$EMAIL\t$SUBSCRIBER\n";
		++$DEADBEATS_COUNT
	}
}


close(RECENT);
close(P2);
close(P3);
close(DEADBEATS);

print "Recent (1.5 years): $RECENT_COUNT\n";
print "P2 (Two years): $P2_COUNT\n";
print "P3 (Three years): $P3_COUNT\n";
print "DEADBEATS: $DEADBEATS_COUNT\n";
print "Number of Accounts we could not find: $LOST_COUNT\n";

# Finally close out our DB connections
$sth->finish();
$dbh->disconnect();
