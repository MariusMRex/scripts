#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## This script derived from user_activity_by_date_minus_suspected_spamtraps.pl
##
## David, representing the board of directors, wants a profile of our subscriber
## activity. I am going to count each catigory for how many folks did or did
## not click/open, and anyone who did not click/open gets moved to the next six month
## category.
##
## Marius April 15th, 2012
##
#####
## O.K.  Lets say we broke people up into 8 categories
## essentially 6 month buckets. Group people by their last known 
## activity.
##
## The earliest click data we have in  newsletter_deal_clicks is 2009-08-17 16:34:31
## The earliest open we have recorded in mailing_campaign_opens is 2009-09-01 13:03:42
##
## So we start with an intial query to get person_ids from derived address
## running whatever other logic the current mailing needs. We then break the remaining
## subscribers down into the above groups and send those to specific IPs on
## the mailers.  As long as the mailers are set up to have a 1 to 1
## relationship between incoming and outgoping IP, we can segment users
## by last activity - Marius 2011-10-21
##
## Added sub-sorting of activity groups by subscription date
## Marius 2011-10-25


my $dbh;                                	# Generic DB Handle
my $sth;
my $HOME = "/home/mking";
my %OPTIONS;
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "db4";          # 10.131.125.94
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
my $FATAL_ERROR;
my $ERROR_INFO;

# Lets get some date information set
(my $SEC, my $MIN, my $HOUR, my $MDAY, my $MON, my $YEAR, my $WDAY, my $YDAY, my $ISDST) = localtime(time);
# Some corrections for Date
$YEAR = $YEAR + 1900;    		# Correct Year output, it is 'off' by 1900 normally
$MON = $MON + 1;     			# Normally months go from 0-11, I want 1-12
# Pad certain date fields if they are too short.
if(length($MON) == "1") {
		    $MON = "0$MON";
}
if(length($MDAY) == "1") {
		    $MDAY = "0$MDAY";
}
if(length($HOUR) == "1") {
		    $HOUR = "0$HOUR";
}
if(length($MIN) == "1") {
		    $MIN = "0$MIN";
}
if(length($SEC) == "1") {
		    $SEC = "0$SEC";
}
my $DATE = "$YEAR-$MON-$MDAY $HOUR:$MIN:$SEC";	# Mysql compatable date format
my $LAST_MONTH = $MON - 1;				# Yes, I know I just added +1 about 20 lines above.
my $LAST_MONTH_DATE = "$YEAR-$LAST_MONTH-$MDAY $HOUR:$MIN:$SEC";
my $MAIL_FILES_HOME = "/home/mking/marii_bin/mailfiles/mailfiles-$YEAR-$MON-$MDAY";

my $SUBSCRIBER;
my @SUBSCRIBER_LIST;
my $SUBSCRIPTION_DATE;
#my $PERSON_ID;
my $EMAIL;
my @PEOPLE_LIST;
my @P1_SUBSCRIBER_LIST;
my @NO_CLICK_P1;                    # Within 6 Months
my @NO_OPEN_P1;                 # Within 6 Months
my @NO_CLICK_P2;                    # 6-12 months April 2011
my @NO_OPEN_P2;                     # 6-12 Months 
my @NO_CLICK_P3;                    # 12-18 Months
my @NO_OPEN_P3;                     # 12-18 Months
my @NO_CLICK_P4;                    # 18-24 Months April 2010
my @NO_OPEN_P4;                     # 18-24 Months
my @NO_CLICK_P5;                    # 24-30 Months
my @NO_OPEN_P5;                     # 24-30 Months
my @NO_CLICK_P6;                    # 30-36 Months April 2009
my @NO_OPEN_P6;                     # 30-36 Months
my @NO_CLICK_P7;                    # No Records recorded
my @NO_OPEN_P7;                     # No records recorded
my $P1_CLICK_COUNT = '0';
my $P1_NO_CLICK_COUNT = '0';
my $P2_CLICK_COUNT = '0';
my $P2_NO_CLICK_COUNT = '0';
my $P3_CLICK_COUNT = '0';
my $P3_NO_CLICK_COUNT = '0';
my $P4_CLICK_COUNT = '0';
my $P4_NO_CLICK_COUNT = '0';
my $P5_CLICK_COUNT = '0';
my $P5_NO_CLICK_COUNT = '0';
my $P6_CLICK_COUNT = '0';
my $P6_NO_CLICK_COUNT = '0';
#my $P7_CLICK_COUNT = '0';
my $P7_NO_CLICK_COUNT = '0';
my $TOTAL_SUBSCRIBERS = "0";
my $TOTAL_ACTIVE_SUBSCRIBERS = "0";
my $LOST_COUNT = "0";

# MYSQL queries and Updates.
# MYSQL queries and Updates.
#my $SUBSCRIBER_QUERY = "SELECT person_id FROM derived_address ORDER BY RAND() LIMIT 500";
my $TOTAL_SUBSCRIBER_QUERY = "SELECT COUNT(*) FROM derived_address WHERE email NOT IN(SELECT email FROM suppression_suspected_spamtraps_2012_03_09)";
my $SUBSCRIBER_QUERY = "SELECT person_id FROM derived_address WHERE created < ? AND (email NOT IN(SELECT email FROM suppression_suspected_spamtraps_2012_03_09))";
my $RECENT_SUBSCRIBER_QUERY = "SELECT COUNT(*) FROM derived_address WHERE created BETWEEN ? AND NOW() AND (email NOT IN(SELECT email FROM suppression_suspected_spamtraps_2012_03_09))";
# P1 Jan 05, 2012 to Today
my $P1_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2012-01-05 23:59:59' AND NOW() LIMIT 1";
my $P1_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2012-01-05 23:59:59' AND NOW() LIMIT 1";

# P2 July 5th, 2011 to Jan 5th, 2012
my $P2_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2011-07-05 00:00:00' AND '2012-01-05 23:59:59' LIMIT 1";
my $P2_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2011-07-05 00:00:00' AND '2012-01-05 23:59:59' LIMIT 1";

# P3 Jan 5th, 2011 to July 5th, 2011
my $P3_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2011-01-05 00:00:00' AND '2011-07-22 23:59:59' LIMIT 1";
my $P3_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2011-01-05 00:00:00' AND '2011-07-22 23:59:59' LIMIT 1";

# P4 July 5th, 2010 to Jan 5th, 2011
my $P4_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2010-07-05 00:00:00' AND '2011-01-05 23:59:59' LIMIT 1";
my $P4_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2010-07-05 00:00:00' AND '2011-01-05 23:59:59' LIMIT 1";

# P5 Jan 5th, 2010 to July 5th, 2010
my $P5_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2010-01-05 00:00:00' AND '2010-07-05 23:59:59' LIMIT 1";
my $P5_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2010-01-05 00:00:00' AND '2010-07-05 23:59:59' LIMIT 1";

# P6 July 5th, 2009 to Jan 5th, 2010
my $P6_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2009-07-05 00:00:00' AND '2010-01-05 23:59:59' LIMIT 1";
my $P6_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2009-07-05 00:00:00' AND '2010-01-05 23:59:59' LIMIT 1";

# P7 Never
# We have no click or open data from before August of 2009
my $NOT_ACTIVE_QUERY = "SELECT email FROM people WHERE id = ?";
my $SORT_BY_SUBSCRIPTION_QUERY = "SELECT created FROM people WHERE id = ?";

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
# First we get total subscribers, minus suspected spam traps.
print "Lets grab the list of people from derived_address...\n";
print "but filter out the current suspected spam trap list\n";
$sth = $dbh->prepare($TOTAL_SUBSCRIBER_QUERY);
$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
$TOTAL_SUBSCRIBERS = $sth->fetchrow();
#print "Value returned: $result->{val}\n";
print "Total Active Subscribers Found: $TOTAL_SUBSCRIBERS\n";


# Now we filter out recent subscribers so we do not erronoiusly think they are inactive
# To 'subscribe' is pretty much an action, so we will count that as active even if we have no clicks or opens.
print "\nNow same thing, except we pre-filer out subscribers who subscribed\n";
print "Between $LAST_MONTH_DATE and $DATE:\n";
$sth = $dbh->prepare($SUBSCRIBER_QUERY);
$sth->execute($LAST_MONTH_DATE) or die "Couldn't execute statement: " . $sth->errstr;
while (@PEOPLE_LIST = $sth->fetchrow_array()) {
	$SUBSCRIBER = $PEOPLE_LIST[0];
	push(@SUBSCRIBER_LIST,$SUBSCRIBER);
	#print "*";
	++$TOTAL_ACTIVE_SUBSCRIBERS;
}
print "Total Active Subscribers Found: $TOTAL_ACTIVE_SUBSCRIBERS\n";


# Lets grab a count of the subscribers we filtered out since they were too recent
$sth = $dbh->prepare($RECENT_SUBSCRIBER_QUERY);
$sth->execute($LAST_MONTH_DATE) or die "Couldn't execute statement: " . $sth->errstr;
my $TOTAL_RECENT_SUBSCRIBERS = $sth->fetchrow();
print "Total Recent Subscribers Found: $TOTAL_RECENT_SUBSCRIBERS\n";

# Lets create a directory, to stick mail files into, if it does not already exist
unless(-d "$MAIL_FILES_HOME") {
	print "Making $MAIL_FILES_HOME for storage of mail files.\n";
	mkdir("$MAIL_FILES_HOME",0777) || die "Cannot mkdir $MAIL_FILES_HOME: $!";
}
# Lets open some mail files for writing to in our special directory
open(P1, ">$MAIL_FILES_HOME/P1.txt");
open(P2, ">$MAIL_FILES_HOME/P2.txt");
open(P3, ">$MAIL_FILES_HOME/P3.txt");
open(P4, ">$MAIL_FILES_HOME/P4.txt");
open(P5, ">$MAIL_FILES_HOME/P5.txt");
open(P6, ">$MAIL_FILES_HOME/P6.txt");
open(P7, ">$MAIL_FILES_HOME/P7.txt");
open(SUMMARY,  ">$MAIL_FILES_HOME/summary.txt"); 

print "START: $DATE\n";
print SUMMARY "START: $DATE\n";

print "Looking for P1 clicks\n";
foreach $SUBSCRIBER(@SUBSCRIBER_LIST) {
	#print "Subscriber is $SUBSCRIBER\n";
	$sth = $dbh->prepare($P1_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they clicked, so we will put them in the mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P1,$SUBSCRIBER);
	} else {
		print P1 "$EMAIL\t$SUBSCRIBER\n";
		++$P1_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for P1 opens\n";   # 2012
foreach $SUBSCRIBER(@NO_CLICK_P1) {
	$sth = $dbh->prepare($P1_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P1,$SUBSCRIBER);
		++$P1_NO_CLICK_COUNT
	} else {
		print P1 "$EMAIL\t$SUBSCRIBER\n";
		++$P1_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}


print "Looking for P2 clicks\n";
foreach $SUBSCRIBER(@NO_OPEN_P1) {
	#print "Subscriber is $SUBSCRIBER\n";
	$sth = $dbh->prepare($P2_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they clicked, so we will put them in the mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P2,$SUBSCRIBER);
	} else {
		print P2 "$EMAIL\t$SUBSCRIBER\n";
		++$P2_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for P2 opens\n";   # 2012
foreach $SUBSCRIBER(@NO_CLICK_P2) {
	$sth = $dbh->prepare($P2_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P2,$SUBSCRIBER);
		++$P2_NO_CLICK_COUNT
	} else {
		print P2 "$EMAIL\t$SUBSCRIBER\n";
		++$P2_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}

print "Looking for P3 clicks\n";
foreach $SUBSCRIBER(@NO_OPEN_P2) {
	#print "Subscriber is $SUBSCRIBER\n";
	$sth = $dbh->prepare($P3_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they clicked, so we will put them in the mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P3,$SUBSCRIBER);
	} else {
		print P3 "$EMAIL\t$SUBSCRIBER\n";
		++$P3_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for P3 opens\n";   # 2012
foreach $SUBSCRIBER(@NO_CLICK_P3) {
	$sth = $dbh->prepare($P3_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P3,$SUBSCRIBER);
		++$P3_NO_CLICK_COUNT
	} else {
		print P3 "$EMAIL\t$SUBSCRIBER\n";
		++$P3_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}

print "Looking for P4 clicks\n";
foreach $SUBSCRIBER(@NO_OPEN_P3) {
	#print "Subscriber is $SUBSCRIBER\n";
	$sth = $dbh->prepare($P4_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they clicked, so we will put them in the mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P4,$SUBSCRIBER);
	} else {
		print P4 "$EMAIL\t$SUBSCRIBER\n";
		++$P4_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for P4 opens\n";   # 2012
foreach $SUBSCRIBER(@NO_CLICK_P4) {
	$sth = $dbh->prepare($P4_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P4,$SUBSCRIBER);
		++$P4_NO_CLICK_COUNT
	} else {
		print P4 "$EMAIL\t$SUBSCRIBER\n";
		++$P4_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}


print "Looking for P5 clicks\n";
foreach $SUBSCRIBER(@NO_OPEN_P4) {
	#print "Subscriber is $SUBSCRIBER\n";
	$sth = $dbh->prepare($P5_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they clicked, so we will put them in the mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P5,$SUBSCRIBER);
	} else {
		print P5 "$EMAIL\t$SUBSCRIBER\n";
		++$P5_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for P5 opens\n";   # 2012
foreach $SUBSCRIBER(@NO_CLICK_P5) {
	$sth = $dbh->prepare($P5_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P5,$SUBSCRIBER);
		++$P5_NO_CLICK_COUNT
	} else {
		print P5 "$EMAIL\t$SUBSCRIBER\n";
		++$P5_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}


print "Looking for P6 clicks\n";
foreach $SUBSCRIBER(@NO_OPEN_P5) {
	#print "Subscriber is $SUBSCRIBER\n";
	$sth = $dbh->prepare($P6_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they clicked, so we will put them in the mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P6,$SUBSCRIBER);
	} else {
		print P6 "$EMAIL\t$SUBSCRIBER\n";
		++$P6_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for P6 opens\n";   # 2012
foreach $SUBSCRIBER(@NO_CLICK_P6) {
	$sth = $dbh->prepare($P6_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P6,$SUBSCRIBER);
		++$P6_NO_CLICK_COUNT
	} else {
		print P6 "$EMAIL\t$SUBSCRIBER\n";
		++$P6_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}

# All that is left is people who do not seem to click or open
print "And now the folks who do not interact at all it seems within the stated periods\n";
foreach $SUBSCRIBER(@NO_OPEN_P6) {
	$sth = $dbh->prepare($NOT_ACTIVE_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
# Any ids we have left appearently did not have any clicks or opens we could find.
# Lets give them their own mailfile.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		++$LOST_COUNT;
	} else {
		print P7 "$EMAIL\t$SUBSCRIBER\n";
		++$P7_NO_CLICK_COUNT
	}
}

close(P1);
close(P2);
close(P3);
close(P4);
close(P5);
close(P6);
close(P7);

print "Adding recent subscribers to most recent activity group... ($P1_CLICK_COUNT + $TOTAL_RECENT_SUBSCRIBERS)\n";
$P1_CLICK_COUNT = $P1_CLICK_COUNT + $TOTAL_RECENT_SUBSCRIBERS;
print "Active in P1 (Last 6 months): $P1_CLICK_COUNT\n";
#print "Not active in P1 (Rolled over to next period): $P1_NO_CLICK_COUNT\n";
print "Active in P2 (Last 7-12 months): $P2_CLICK_COUNT\n";
#print "Not active in P2 (Rolled over to next period): $P2_NO_CLICK_COUNT\n";
print "Active in P3 (Last 13-18 months): $P3_CLICK_COUNT\n";
#print "Not active in P3 (Rolled over to next period): $P3_NO_CLICK_COUNT\n";
print "Active in P4 (Last 19-24 months): $P4_CLICK_COUNT\n";
#print "Not active in P4 (Rolled over to next period): $P4_NO_CLICK_COUNT\n";
print "Active in P5 (Last 25-30 months): $P5_CLICK_COUNT\n";
#print "Not active in P5 (Rolled over to next period): $P5_NO_CLICK_COUNT\n";
print "Active in P6 (Last 31-36 months): $P6_CLICK_COUNT\n";
#print "Not active in P6 (Rolled over to next period): $P6_NO_CLICK_COUNT\n";
print "No Activity Found: $P7_NO_CLICK_COUNT\n";
print "Number of Accounts we could not find: $LOST_COUNT\n";

print "Writing out summary file\n";
print SUMMARY "Total Subscribers Found: $TOTAL_SUBSCRIBERS\n";
print SUMMARY "Adding recent subscribers to most recent activity group... ($P1_CLICK_COUNT + $TOTAL_RECENT_SUBSCRIBERS)\n";
#$P1_CLICK_COUNT = $P1_CLICK_COUNT + $TOTAL_RECENT_SUBSCRIBERS;
print SUMMARY "Active in P1 (Last 6 months): $P1_CLICK_COUNT\n";
#print SUMMARY "Not active in P1 (Rolled over to next period): $P1_NO_CLICK_COUNT\n";
print SUMMARY "Active in P2 (Last 7-12 months): $P2_CLICK_COUNT\n";
#print SUMMARY "Not active in P2 (Rolled over to next period): $P2_NO_CLICK_COUNT\n";
print SUMMARY "Active in P3 (Last 13-18 months): $P3_CLICK_COUNT\n";
#print SUMMARY "Not active in P3 (Rolled over to next period): $P3_NO_CLICK_COUNT\n";
print SUMMARY "Active in P4 (Last 19-24 months): $P4_CLICK_COUNT\n";
#print SUMMARY "Not active in P4 (Rolled over to next period): $P4_NO_CLICK_COUNT\n";
print SUMMARY "Active in P5 (Last 25-30 months): $P5_CLICK_COUNT\n";
#print SUMMARY "Not active in P5 (Rolled over to next period): $P5_NO_CLICK_COUNT\n";
print SUMMARY "Active in P6 (Last 31-36 months): $P6_CLICK_COUNT\n";
#print SUMMARY "Not active in P6 (Rolled over to next period): $P6_NO_CLICK_COUNT\n";
print SUMMARY "No Activity Found: $P7_NO_CLICK_COUNT\n";
print SUMMARY "Number of Accounts we could not find: $LOST_COUNT\n";

$DATE = `date`;
print SUMMARY "END: $DATE\n";

# Finally close out our DB connections
$sth->finish();
$dbh->disconnect();
