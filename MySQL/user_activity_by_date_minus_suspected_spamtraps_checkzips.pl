#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## Current Request: 2012-04-05
## Sandy has asked for the counts of our active users sorting out who has a zip code and who does not, to aid in making the decision of how many to scrub. 
## Can you please provide me with the following info:
##
## Active (opened or clicked) within the last 1.5 years: Numbers with zipcode, those without
## Active (opened or clicked) within the last 2 years: Numbers with zipcode, those without 
## Active (opened or clicked) within the last 3 years: Numbers with zipcode, those without
## Inactive (No opens or clicks) recorded in DB, sorted int zipcodes and no zipcode identified users.
## Total subscriber count as of the time you ran these queries (so I can extrapolate how many names would be scrubbed):

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
#my $DATE = "$YEAR-$MON-$MDAY $HOUR:$MIN:$SEC";	# Mysql compatable date format
my $LAST_YEAR = $YEAR - 1;
my $LAST_YEAR_DATE = "$LAST_YEAR-$MON-$MDAY $HOUR:$MIN:$SEC";	# Mysql compatable date format
my $MAIL_FILES_HOME = "/home/mking/marii_bin/mailfiles/mailfiles-$YEAR-$MON-$MDAY";


my $SUBSCRIBER;
my @SUBSCRIBER_LIST;
my $SUBSCRIPTION_DATE;
#my $PERSON_ID;
my $EMAIL;
my $POSTAL_CODE;
my @PEOPLE_LIST;
my @CURRENT_SUBSCRIBER_LIST;
my @NO_CLICK_RECENT;
my @NO_OPEN_RECENT;
my @NO_CLICK_P2;
my @NO_OPEN_P2;
my @NO_CLICK_P3;
my @NO_OPEN_P3;
my @NO_CLICK_P4;
my @NO_OPEN_P4;
my $SUBSCRIPTION_YEAR;
my $TOTAL_ACTIVE_SUBSCRIBERS = "0";
my $LOST_COUNT = "0";
my $RECENT_ZIP_COUNT = "0";
my $RECENT_NOZIP_COUNT = "0";
my $P2_ZIP_COUNT = "0";
my $P2_NOZIP_COUNT = "0";
my $P3_ZIP_COUNT = "0";
my $P3_NOZIP_COUNT = "0";
my $P4_ZIP_COUNT = "0";
my $P4_NOZIP_COUNT = "0";
my $DEADBEATS_ZIP_COUNT = "0";
my $DEADBEATS_NOZIP_COUNT = "0";

# MYSQL queries and Updates.
# Get a list of users, filtering out anyone what was not registered at least six months ago
my $SUBSCRIBER_QUERY = "SELECT person_id FROM derived_address WHERE created < ? AND (email NOT IN(SELECT email FROM suppression_suspected_spamtraps_2012_03_09))";  
# Clicked  or opened this year
my $RECENT_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2012-01-01 00:00:00' AND NOW() LIMIT 1";
my $RECENT_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2012-01-01 00:00:00' AND NOW() LIMIT 1";
# Access archived tables for pre-2012 opens and clicks
# 2011
my $P2_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks_pre_2012 AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2011-01-01 00:00:00' AND '2011-12-31 23:59:59' LIMIT 1";
my $P2_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens_pre_2012 AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2011-01-01 00:00:00' AND '2011-12-31 23:59:59' LIMIT 1";
# 2010
my $P3_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks_pre_2012 AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2010-01-01 00:00:00' AND '2010-12-31 23:59:59' LIMIT 1";
my $P3_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens_pre_2012 AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2010-01-01 00:00:00' AND '2010-12-31 23:59:59' LIMIT 1";
# 2009
my $P4_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks_pre_2012 AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2009-01-01 00:00:00' AND '2009-12-31 23:59:59' LIMIT 1";
my $P4_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens_pre_2012 AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2009-01-01 00:00:00' AND '2009-12-31 23:59:59' LIMIT 1";
# We have no click or open data from before August of 2009
my $NOT_ACTIVE_QUERY = "SELECT email FROM people WHERE id = ?";
# Grab postal code
my $ZIP_QUERY = "SELECT postal_code FROM derived_address WHERE person_id = ?";

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
print "Lets grab the list of people from derived_address\n";
print "In order to filter out new users, lets set a limit of created < $LAST_YEAR_DATE\n";
print "Lets also filter out the current suspected spam trap list\n";
$sth = $dbh->prepare($SUBSCRIBER_QUERY);
$sth->execute($LAST_YEAR_DATE) or die "Couldn't execute statement: " . $sth->errstr;
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
open(RECENT, ">$MAIL_FILES_HOME/2012.txt");
open(P2, ">$MAIL_FILES_HOME/2011.txt");
open(P3, ">$MAIL_FILES_HOME/2010.txt");
open(P4, ">$MAIL_FILES_HOME/2009.txt");
open(DEADBEATS, ">$MAIL_FILES_HOME/no-activity.txt");

my $RECENT_COUNT = "0";
my $P2_COUNT = "0";
my $P3_COUNT = "0";
my $P4_COUNT = "0";
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
print "Looking for recent opens\n";   # 2012
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

# interaction in 2010
print "Looking for clicks in 2011\n";
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
print "Looking for opens in 2011\n";
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


# interaction in 2010
print "Looking for clicks 2010\n";
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
print "Looking for opens 2010\n";
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

# interaction in 2009
print "Looking for clicks 2009\n";
foreach $SUBSCRIBER(@NO_OPEN_P3) {
	$sth = $dbh->prepare($P4_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P4,$SUBSCRIBER);
	} else {
		print P4 "$EMAIL\t$SUBSCRIBER\n";
		++$P4_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for opens 2009\n";
foreach $SUBSCRIBER(@NO_CLICK_P4) {
	$sth = $dbh->prepare($P4_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P4,$SUBSCRIBER);
	} else {
		print P4 "$EMAIL\t$SUBSCRIBER\n";
		++$P4_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}

# All that is left is people who do not seem to click or open
print "And now the folks who do not interact at all it seems within the stated periods\n";
foreach $SUBSCRIBER(@NO_OPEN_P4) {
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
close(P4);
close(DEADBEATS);

print "Recent (2012): $RECENT_COUNT\n";
print "P2 (2011): $P2_COUNT\n";
print "P3 (2010): $P3_COUNT\n";
print "P4 (2009): $P4_COUNT\n";
print "No Activity Found: $DEADBEATS_COUNT\n";
print "Number of Accounts we could not find: $LOST_COUNT\n";

## Now we check zips

# Re-open data files for reading:
open(RECENT, "$MAIL_FILES_HOME/2012.txt");
open(P2, "$MAIL_FILES_HOME/2011.txt");
open(P3, "$MAIL_FILES_HOME/2010.txt");
open(P4, "$MAIL_FILES_HOME/2009.txt");
open(DEADBEATS, "$MAIL_FILES_HOME/no-activity.txt");
# And my zip files
open(RECENT_ZIP, ">$MAIL_FILES_HOME/2012-zip.txt");
open(P2_ZIP, ">$MAIL_FILES_HOME/2011-zip.txt");
open(P3_ZIP, ">$MAIL_FILES_HOME/2010-zip.txt");
open(P4_ZIP, ">$MAIL_FILES_HOME/2009-zip.txt");
open(DEADBEATS_ZIP, ">$MAIL_FILES_HOME/no-activity-zip.txt");
# My non-zip files
open(RECENT_NOZIP, ">$MAIL_FILES_HOME/2012_nozip.txt");
open(P2_NOZIP, ">$MAIL_FILES_HOME/2011_nozip.txt");
open(P3_NOZIP, ">$MAIL_FILES_HOME/2010_nozip.txt");
open(P4_NOZIP, ">$MAIL_FILES_HOME/2009_nozip.txt");
open(DEADBEATS_NOZIP, ">$MAIL_FILES_HOME/no-activity-nozip.txt");

while(<RECENT>) {
	chomp;
	($EMAIL,$SUBSCRIBER) = split(/\t/);
	$sth = $dbh->prepare($ZIP_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	$POSTAL_CODE = $sth->fetchrow();
	if($sth->rows == 0) {
		print RECENT_NOZIP "$EMAIL\t$SUBSCRIBER\n";
		++$RECENT_NOZIP_COUNT;
	} else {
		if($POSTAL_CODE) {
			if($POSTAL_CODE =~ /[\w\-]{5,}/) {
				print RECENT_ZIP "$EMAIL\t$SUBSCRIBER\t$POSTAL_CODE\n";
				++$RECENT_ZIP_COUNT;
			} else {
				print RECENT_NOZIP "$EMAIL\t$SUBSCRIBER\n";
				++$RECENT_NOZIP_COUNT;
			}
		} else {
			print RECENT_NOZIP "$EMAIL\t$SUBSCRIBER\n";
			++$RECENT_NOZIP_COUNT;
		}
	}
}
while(<P2>) {
	chomp;
	($EMAIL,$SUBSCRIBER) = split(/\t/);
	$sth = $dbh->prepare($ZIP_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	$POSTAL_CODE = $sth->fetchrow();
	if($sth->rows == 0) {
		print P2_NOZIP "$EMAIL\t$SUBSCRIBER\n";
		++$P2_NOZIP_COUNT;
	} else {
		if($POSTAL_CODE) {
			if($POSTAL_CODE =~ /[\w\-]{5,}/) {
				print P2_ZIP "$EMAIL\t$SUBSCRIBER\t$POSTAL_CODE\n";
				++$P2_ZIP_COUNT;
			} else {
				print P2_NOZIP "$EMAIL\t$SUBSCRIBER\n";
				++$P2_NOZIP_COUNT;
			}
		} else {
			print P2_NOZIP "$EMAIL\t$SUBSCRIBER\n";
			++$P2_NOZIP_COUNT;
		}
	}
}
while(<P3>) {
	chomp;
	($EMAIL,$SUBSCRIBER) = split(/\t/);
	$sth = $dbh->prepare($ZIP_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	$POSTAL_CODE = $sth->fetchrow();
	if($sth->rows == 0) {
		print P3_NOZIP "$EMAIL\t$SUBSCRIBER\n";
		++$P3_NOZIP_COUNT;
	} else {
		if($POSTAL_CODE) {
			if($POSTAL_CODE =~ /[\w\-]{5,}/) {
				print P3_ZIP "$EMAIL\t$SUBSCRIBER\t$POSTAL_CODE\n";
				++$P3_ZIP_COUNT;
			} else {
				print P3_NOZIP "$EMAIL\t$SUBSCRIBER\n";
				++$P3_NOZIP_COUNT;
			}
		} else {
			print P3_NOZIP "$EMAIL\t$SUBSCRIBER\n";
			++$P3_NOZIP_COUNT;
		}
	}
}
while(<P4>) {
	chomp;
	($EMAIL,$SUBSCRIBER) = split(/\t/);
	$sth = $dbh->prepare($ZIP_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	$POSTAL_CODE = $sth->fetchrow();
	if($sth->rows == 0) {
		print P4_NOZIP "$EMAIL\t$SUBSCRIBER\n";
		++$P4_NOZIP_COUNT;
	} else {
		if($POSTAL_CODE) {
			if($POSTAL_CODE =~ /[\w\-]{5,}/) {
				print P4_ZIP "$EMAIL\t$SUBSCRIBER\t$POSTAL_CODE\n";
				++$P4_ZIP_COUNT;
			} else {
				print P4_NOZIP "$EMAIL\t$SUBSCRIBER\n";
				++$P4_NOZIP_COUNT;
			}
		} else {
			print P4_NOZIP "$EMAIL\t$SUBSCRIBER\n";
			++$P4_NOZIP_COUNT;
		}
	}
}
while(<DEADBEATS>) {
	chomp;
	($EMAIL,$SUBSCRIBER) = split(/\t/);
	$sth = $dbh->prepare($ZIP_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	$POSTAL_CODE = $sth->fetchrow();
	if($sth->rows == 0) {
		print DEADBEATS_NOZIP "$EMAIL\t$SUBSCRIBER\n";
		++$DEADBEATS_NOZIP_COUNT;
	} else {
		if($POSTAL_CODE) {
			if($POSTAL_CODE =~ /[\w\-]{5,}/) {
				print DEADBEATS_ZIP "$EMAIL\t$SUBSCRIBER\t$POSTAL_CODE\n";
				++$DEADBEATS_ZIP_COUNT;
			} else {
				print DEADBEATS_NOZIP "$EMAIL\t$SUBSCRIBER\n";
				++$DEADBEATS_NOZIP_COUNT;
			}
		} else {
			print DEADBEATS_NOZIP "$EMAIL\t$SUBSCRIBER\n";
			++$DEADBEATS_NOZIP_COUNT;
		}
	}
}

# Some totals
print "##########\n\n##########\n";
print "Recent with zip: $RECENT_ZIP_COUNT\n";
print "Recent without zip: $RECENT_NOZIP_COUNT\n";
print "2011 with zip: $P2_ZIP_COUNT\n";
print "2011 without zip: $P2_NOZIP_COUNT\n";
print "2010 with zip: $P3_ZIP_COUNT\n";
print "2010 without zip: $P3_NOZIP_COUNT\n";
print "2009 with zip: $P4_ZIP_COUNT\n";
print "2009 without zip: $P4_NOZIP_COUNT\n";
print "No Activity with zip: $DEADBEATS_ZIP_COUNT\n";
print "No Activity without zip: $DEADBEATS_NOZIP_COUNT\n";

# Finally close out our DB connections
$sth->finish();
$dbh->disconnect();
