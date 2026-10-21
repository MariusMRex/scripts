#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## To find spam traps we need to sort users by last time they
## interacted with a mailing
## Marius 2011-10-19

## O.K.  Lets say we broke people up into 8 categories
## essentially 6 month buckets. Group people by their last known 
## activity: late 2011, early 2011, late 2010, early 2010, and late 2009.
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
## Lets pre-pend a segment of users who were obtained by co-registration
## to see if that yields significant spam traps - Marius 2011-10-24
##
## Added sub-sorting of activity groups by subscription date
## Marius 2011-10-25
## 
## Branching the original script as I want to focus on folks who were last active in 2010 
## and subscribed in 2008 or earlier. -Marius 2011-10-31

my $dbh;                                	# Generic DB Handle
my $sth;
my $HOME = "/home/mking";
my $MAIL_FILES_HOME = "/home/mking/marii_bin/mailfiles/2010_activity";
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
my @POSSIBLE_SPAM_TRAP_LIST;
my @CURRENT_SUBSCRIBER_LIST;
my @CO_REG_LIST;					# Subscribers obtained through co-registration sources
my @NO_CLICK_CO_REG_LIST;
my @NO_CLICK_RECENT;
my @NO_OPEN_RECENT;
my @NO_CLICK_P1_2011;
my @NO_OPEN_P1_2011;
my @NO_CLICK_P1_2010;
my @NO_OPEN_P1_2010;
my @NO_CLICK_P2_2010;
my @NO_OPEN_P2_2010;
my @NO_CLICK_P2_2009;
my @NO_OPEN_P2_2009;
my $SUBSCRIPTION_YEAR;
my $SUBSCRIPTION_MONTH;
my $TOTAL_ACTIVE_SUBSCRIBERS = "0";
my $TOTAL_POSSIBLY_UNCLEAN_SUBSCRIBERS = "0";
my $LOST_COUNT = "0";
# Referrer IDs for segmenting out co-registration sources.
# Lifescript D25-Lifescript-t25 ID 29445317 
#my $LIFESCRIPT_REFER_SOURCE_PEOPLE = "http://lsa.lifescript.com/advantage/hp8831/main.aspx?utm_campaign=hp"; 
# Pontiflex D25-Pontiflex% ID (There are 60+)
#my $PONTIFLEX_REFER_SOURCE_PEOPLE = "http://www.pontiflex.com/";

## MYSQL queries and Updates.

# All of these users should be last active in 2010 and were subscribed in 2008 or earlier.
my $SUBSCRIBER_QUERY = "SELECT email FROM possible_spam_trap_addresses_2011_10_31";   
my $PERSON_ID_QUERY = "SELECT id FROM people WHERE email = ?";
my $CO_REGISTRATION_QUERY = "SELECT p.email FROM people AS p WHERE p.id = ? AND (source = 'http://www.pontiflex.com/' OR source = 'http://lsa.lifescript.com/advantage/hp8831/main.aspx?utm_campaign=hp')"; 
my $RECENT_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2011-07-01 00:00:00' AND NOW() LIMIT 1";
my $RECENT_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2011-07-01 00:00:00' AND NOW() LIMIT 1";
my $P1_2011_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2011-01-01 00:00:00' AND '2011-06-31 23:59:59' LIMIT 1";
my $P1_2011_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2011-01-01 00:00:00' AND '2011-06-31 23:59:59' LIMIT 1";
my $P2_2010_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2010-07-01 00:00:00' AND '2010-12-31 23:59:59' LIMIT 1"; 
my $P2_2010_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2010-07-01 00:00:00' AND '2010-12-31 23:59:59' LIMIT 1";
my $P1_2010_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2010-01-01 00:00:00' AND '2010-06-31 23:59:59' LIMIT 1";
my $P1_2010_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2010-01-01 00:00:00' AND '2010-06-31 23:59:59' LIMIT 1";
my $P2_2009_CLICK_QUERY = "SELECT p.email FROM newsletter_deal_clicks AS ndc, people AS p WHERE p.id = ? AND ndc.person_id = p.id AND ndc.modified BETWEEN '2009-07-01 00:00:00' AND '2009-12-31 23:59:59' LIMIT 1";
my $P2_2009_OPEN_QUERY = "SELECT p.email FROM mailing_campaign_opens AS mco, people AS p WHERE p.id = ? AND mco.person_id = p.id AND mco.modified BETWEEN '2009-07-01 00:00:00' AND '2009-12-31 23:59:59' LIMIT 1";
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

# O.K.  Lets get a list of users
print "Lets grab the list of people from the spam trap profile pool\n";
$sth = $dbh->prepare($SUBSCRIBER_QUERY);
$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
while (@PEOPLE_LIST = $sth->fetchrow_array()) {
	$EMAIL = $PEOPLE_LIST[0];
	push(@POSSIBLE_SPAM_TRAP_LIST,$EMAIL);
	++$TOTAL_POSSIBLY_UNCLEAN_SUBSCRIBERS;
}
print "Total Active Possibly unclean subscribers found: $TOTAL_POSSIBLY_UNCLEAN_SUBSCRIBERS\n";

# Lets convert those to people IDs so we can play with the normal script.
print "Converting to person_id\n";
foreach $EMAIL(@POSSIBLE_SPAM_TRAP_LIST) {
	$sth = $dbh->prepare($PERSON_ID_QUERY);
	$sth->execute($EMAIL) or die "Couldn't execute statement: " . $sth->errstr;
	while (@PEOPLE_LIST = $sth->fetchrow_array()) {
		$SUBSCRIBER = $PEOPLE_LIST[0];
		push(@CURRENT_SUBSCRIBER_LIST,$SUBSCRIBER);
		++$TOTAL_ACTIVE_SUBSCRIBERS;
	}
}
print "Total email addresses converted to people_ids: $TOTAL_ACTIVE_SUBSCRIBERS\n";

# Lets create a directory, to stick mail files into, if it does not already exist
unless(-d "$MAIL_FILES_HOME") {
	print "Making $MAIL_FILES_HOME for storage of mail files.\n";
	mkdir("$MAIL_FILES_HOME",0777) || die "Cannot mkdir $MAIL_FILES_HOME: $!";
}
# Lets open some mail files for writing to in our special directory
open(COREG, ">$MAIL_FILES_HOME/co-registration.txt");
open(RECENT, ">$MAIL_FILES_HOME/late2011.txt");
open(P1_2011, ">$MAIL_FILES_HOME/early2011.txt");
open(P2_2010, ">$MAIL_FILES_HOME/late2010.txt");
open(P1_2010, ">$MAIL_FILES_HOME/early2010.txt");
open(P2_2009, ">$MAIL_FILES_HOME/late2009.txt");
open(DEADBEATS, ">$MAIL_FILES_HOME/no-activity.txt");

my $CO_REGS_COUNT = "0";
my $RECENT_COUNT = "0";
my $P1_2011_COUNT = "0";
my $P2_2010_COUNT = "0";
my $P1_2010_COUNT = "0";
my $P2_2009_COUNT = "0";
my $DEADBEATS_COUNT = "0";

# Filter out Subscribers with a co-registration source first
# We are doing this regarless of clicks or opens.
print "Looking for subscribers with a co-registration source.\n";
foreach $SUBSCRIBER(@CURRENT_SUBSCRIBER_LIST) {
	$sth = $dbh->prepare($CO_REGISTRATION_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
# If we get a hit, the source is from a co-registration source, so we will put them in a unique mail file
# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_CO_REG_LIST,$SUBSCRIBER);
	} else {
		print COREG "$EMAIL\t$SUBSCRIBER\n";
		++$CO_REGS_COUNT;
#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
# Recent Interaction
print "Looking for recent clicks\n";
foreach $SUBSCRIBER(@NO_CLICK_CO_REG_LIST) {
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
print "Looking for recent opens\n";
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

# interaction in first half of 2011
print "Looking for clicks 2011 p1\n";
foreach $SUBSCRIBER(@NO_OPEN_RECENT) {
	$sth = $dbh->prepare($P1_2011_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P1_2011,$SUBSCRIBER);
	} else {
		print P1_2011 "$EMAIL\t$SUBSCRIBER\n";
		++$P1_2011_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for opens 2011 p1\n";
foreach $SUBSCRIBER(@NO_CLICK_P1_2011) {
	$sth = $dbh->prepare($P1_2011_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P1_2011,$SUBSCRIBER);
	} else {
		print P1_2011 "$EMAIL\t$SUBSCRIBER\n";
		++$P1_2011_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}


# interaction in second half of 2010
print "Looking for clicks 2010 p2\n";
foreach $SUBSCRIBER(@NO_OPEN_P1_2011) {
	$sth = $dbh->prepare($P2_2010_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P2_2010,$SUBSCRIBER);
	} else {
		print P2_2010 "$EMAIL\t$SUBSCRIBER\n";
		++$P2_2010_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for opens 2010 p2\n";
foreach $SUBSCRIBER(@NO_CLICK_P2_2010) {
	$sth = $dbh->prepare($P2_2010_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P2_2010,$SUBSCRIBER);
	} else {
		print P2_2010 "$EMAIL\t$SUBSCRIBER\n";
		++$P2_2010_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}

# interaction in first half of 2010
print "Looking for clicks 2010 p1\n";
foreach $SUBSCRIBER(@NO_OPEN_P2_2010) {
	$sth = $dbh->prepare($P1_2010_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P1_2010,$SUBSCRIBER);
	} else {
		print P1_2010 "$EMAIL\t$SUBSCRIBER\n";
		++$P1_2010_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for opens 2011 p1\n";
foreach $SUBSCRIBER(@NO_CLICK_P1_2010) {
	$sth = $dbh->prepare($P1_2010_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P1_2010,$SUBSCRIBER);
	} else {
		print P1_2010 "$EMAIL\t$SUBSCRIBER\n";
		++$P1_2010_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}

# interaction in second half of 2009
print "Looking for clicks 2009 p2\n";
foreach $SUBSCRIBER(@NO_OPEN_P1_2010) {
	$sth = $dbh->prepare($P2_2009_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P2_2009,$SUBSCRIBER);
	} else {
		print P2_2009 "$EMAIL\t$SUBSCRIBER\n";
		++$P2_2009_COUNT
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for opens 2009 p2\n";
foreach $SUBSCRIBER(@NO_CLICK_P2_2009) {
	$sth = $dbh->prepare($P2_2009_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$EMAIL = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P2_2009,$SUBSCRIBER);
	} else {
		print P2_2009 "$EMAIL\t$SUBSCRIBER\n";
		#print "Putting $SUBSCRIBER in current bucket\n";
		++$P2_2009_COUNT
	}
}

# All that is left is people who do not seem to click or open
print "And now the folks who do not interact at all it seems...\n";
foreach $SUBSCRIBER(@NO_OPEN_P2_2009) {
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

close(COREG);
close(RECENT);
close(P1_2011);
close(P2_2010);
close(P1_2010);
close(P2_2009);
close(DEADBEATS);

print "Possibly unclean emails to start with $TOTAL_POSSIBLY_UNCLEAN_SUBSCRIBERS\n";
print "Co-Registration: $CO_REGS_COUNT\n";
print "Recent: $RECENT_COUNT\n";
print "P1 2011: $P1_2011_COUNT\n";
print "P2 2010: $P2_2010_COUNT\n";
print "P1 2010: $P1_2010_COUNT\n";
print "P2 2009: $P2_2009_COUNT\n";
print "DEADBEATS: $DEADBEATS_COUNT\n";
print "Number of Accounts we could not find: $LOST_COUNT\n";

#print "Bug: Mail files14 and 15 have duplicates.!!!\n";
#print "Figure this out before proceeding. mailer14 is all duplicates and mailer 15 is mostly duplicates\n";
#exit 1;

## O.K.  Can we split up the users by time zone?
#foreach $FILE(@RAW_MAILFILES) {
#	open(RAW_FILE, "$FILE");
#
## Time zone splitting stalled as it does not help
## spam trap detection, as we do nto think spam traps
## are likely geographically related.

## Lets sub-divide our pre-defined activity groups by 
## date the user subscribed.

## So redux to focus on possible spam traps
## mailer1 unknown subscription date
## mailer2 Subscribed P1 2004 or earlier
## mailer3 Subscribed P1 2005
## mailer4 Subscribed P2 2005
## mailer5 Subscribed P1 2006
## mailer6 Subscribed P2 2006
## mailer7 Subscribed P1 2007
## mailer8 Subscribed P2 2007
## mailer9 Subscribed P1 2008
## mailer10 Subscribed P2 2008
## mailer11 Subscribed P1 2009
## mailer12 Subscribed P2 2009
## mailer13 Subscribed P1 2010
## mailer14 Subscribed P2 2010
## mailer15 Subscribed 2011
my @PROCESSED_MAILFILES = qw( $MAIL_FILES_HOME/master.txt $MAIL_FILES_HOME/mailer1.txt $MAIL_FILES_HOME/mailer2.txt	$MAIL_FILES_HOME/mailer2.txt $MAIL_FILES_HOME/mailer3.txt $MAIL_FILES_HOME/mailer4.txt $MAIL_FILES_HOME/mailer4.txt $MAIL_FILES_HOME/mailer5.txt $MAIL_FILES_HOME/mailer6.txt $MAIL_FILES_HOME/mailer7.txt $MAIL_FILES_HOME/mailer8.txt $MAIL_FILES_HOME/mailer9.txt $MAIL_FILES_HOME/mailer10.txt $MAIL_FILES_HOME/mailer11.txt $MAIL_FILES_HOME/mailer12.txt $MAIL_FILES_HOME/mailer13.txt $MAIL_FILES_HOME/mailer14.txt $MAIL_FILES_HOME/mailer15.txt);
open(MASTER, ">$MAIL_FILES_HOME/master.txt"); 
open(MAILER1, ">$MAIL_FILES_HOME/mailer1.txt");
open(MAILER2, ">$MAIL_FILES_HOME/mailer2.txt");
open(MAILER3, ">$MAIL_FILES_HOME/mailer3.txt");
open(MAILER4, ">$MAIL_FILES_HOME/mailer4.txt");
open(MAILER5, ">$MAIL_FILES_HOME/mailer5.txt");
open(MAILER6, ">$MAIL_FILES_HOME/mailer6.txt");
open(MAILER7, ">$MAIL_FILES_HOME/mailer7.txt");
open(MAILER8, ">$MAIL_FILES_HOME/mailer8.txt");
open(MAILER9, ">$MAIL_FILES_HOME/mailer9.txt");
open(MAILER10, ">$MAIL_FILES_HOME/mailer10.txt");
open(MAILER11, ">$MAIL_FILES_HOME/mailer11.txt");
open(MAILER12, ">$MAIL_FILES_HOME/mailer12.txt");
open(MAILER13, ">$MAIL_FILES_HOME/mailer13.txt");
open(MAILER14, ">$MAIL_FILES_HOME/mailer14.txt");
open(MAILER15, ">$MAIL_FILES_HOME/mailer15.txt");

# Open some file handles for reading
open(COREG_RO, "$MAIL_FILES_HOME/co-registration.txt");
open(RECENT_RO, "$MAIL_FILES_HOME/late2011.txt");
open(P1_2011_RO, "$MAIL_FILES_HOME/early2011.txt");
open(P2_2010_RO, "$MAIL_FILES_HOME/late2010.txt");
open(P1_2010_RO, "$MAIL_FILES_HOME/early2010.txt");
open(P2_2009_RO, "$MAIL_FILES_HOME/late2009.txt");
open(DEADBEATS_RO, "$MAIL_FILES_HOME/no-activity.txt");

##  There should be no co-regs at all
#print "Populating co-registration file.\n";
#while(<COREG_RO>) {
#	chomp;
#	if($_ =~ /.+\@.+\..+\t\d\d+/) {
#		($EMAIL,$SUBSCRIBER) = split(/\t/);
# Every email address should go in master.txt, as other mailing scripts depend on it
#		print MASTER "$EMAIL\t$SUBSCRIBER\n";
#		print COREG "$EMAIL\t$SUBSCRIBER\n";
#	}
#}

# Late 2011 activity
print "Sub-sorting late 2011 by subscription date.\n";
while(<RECENT_RO>) {
	chomp;
	if($_ =~ /.+\@.+\..+\t\d\d+/) {
		($EMAIL,$SUBSCRIBER) = split(/\t/);
# Every email address should go in master.txt, as other mailing scripts depend on it
		print MASTER "$EMAIL\t$SUBSCRIBER\n";
# Sort by date subscribed
		$sth = $dbh->prepare($SORT_BY_SUBSCRIPTION_QUERY);
		$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
		$SUBSCRIPTION_DATE = $sth->fetchrow();
		if($sth->rows == 0) {
# User has no subscription Date, so dump it in 'MAILER1'
			print "No rows returned from date query\n";
			print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
		} else {
# Does our date look valid?
			if($SUBSCRIPTION_DATE eq "0000-00-00 00:00:00") {
# No date provided, so we go to MAILER1
				print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
				next;
			}
			if($SUBSCRIPTION_DATE =~ /(20\d\d)-(\d\d)-\d\d\s\d\d:\d\d:\d\d$/) {
				#print "Good hit for year: $SUBSCRIPTION_YEAR\n";
				$SUBSCRIPTION_YEAR = $1;
				$SUBSCRIPTION_MONTH = $2;
# fix dates like 06 to read 6 for numeric comparison
				if($SUBSCRIPTION_MONTH =~ /0(\d)/) {
					$SUBSCRIPTION_MONTH = $1;
				}
				if($SUBSCRIPTION_YEAR == "2011") {
					print MAILER15 "$EMAIL\t$SUBSCRIBER\n";
				} elsif ($SUBSCRIPTION_YEAR == "2010") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER13 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER14 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2009") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER11 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER12 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2008") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER9 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER10 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2007") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER7 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER8 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2006") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER5 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER6 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2005") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER3 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER4 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR <= "2004") {
						print MAILER2 "$EMAIL\t$SUBSCRIBER\n";
				}
			} else {
# Something went wrong, so dump it in 'MAILER1'
					print "Miss on Year: $SUBSCRIPTION_DATE\n";
					print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
			}
		}
	}
}

# Early 2011 activity
print "Sub-sorting early 2011 by subscription date.\n";
while(<P1_2011_RO>) {
	chomp;
	if($_ =~ /.+\@.+\..+\t\d\d+/) {
		($EMAIL,$SUBSCRIBER) = split(/\t/);
# Every email address should go in master.txt, as other mailing scripts depend on it
		print MASTER "$EMAIL\t$SUBSCRIBER\n";
# Sort by date subscribed
		$sth = $dbh->prepare($SORT_BY_SUBSCRIPTION_QUERY);
		$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
		$SUBSCRIPTION_DATE = $sth->fetchrow();
		if($sth->rows == 0) {
# User has no subscription Date, so dump it in 'MAILER1'
			print "No rows returned from date query\n";
			print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
		} else {
# Does our date look valid?
			if($SUBSCRIPTION_DATE eq "0000-00-00 00:00:00") {
# No date provided, so we go to MAILER1
				print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
				next;
			}
			if($SUBSCRIPTION_DATE =~ /(20\d\d)-(\d\d)-\d\d\s\d\d:\d\d:\d\d$/) {
				#print "Good hit for year: $SUBSCRIPTION_YEAR\n";
				$SUBSCRIPTION_YEAR = $1;
				$SUBSCRIPTION_MONTH = $2;
# fix dates like 06 to read 6 for numeric comparison
				if($SUBSCRIPTION_MONTH =~ /0(\d)/) {
					$SUBSCRIPTION_MONTH = $1;
				}
				if($SUBSCRIPTION_YEAR == "2011") {
					print MAILER15 "$EMAIL\t$SUBSCRIBER\n";
				} elsif ($SUBSCRIPTION_YEAR == "2010") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER13 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER14 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2009") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER11 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER12 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2008") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER9 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER10 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2007") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER7 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER8 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2006") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER5 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER6 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2005") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER3 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER4 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR <= "2004") {
						print MAILER2 "$EMAIL\t$SUBSCRIBER\n";
				}
			} else {
# Something went wrong, so dump it in 'MAILER1'
					print "Miss on Year: $SUBSCRIPTION_DATE\n";
					print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
			}
		}
	}
}

# Late 2010 activity
print "Sub-sorting late 2010 by subscription date.\n";
while(<P2_2010_RO>) {
	chomp;
	if($_ =~ /.+\@.+\..+\t\d\d+/) {
		($EMAIL,$SUBSCRIBER) = split(/\t/);
# Every email address should go in master.txt, as other mailing scripts depend on it
		print MASTER "$EMAIL\t$SUBSCRIBER\n";
# Sort by date subscribed
		$sth = $dbh->prepare($SORT_BY_SUBSCRIPTION_QUERY);
		$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
		$SUBSCRIPTION_DATE = $sth->fetchrow();
		if($sth->rows == 0) {
# User has no subscription Date, so dump it in 'MAILER1'
			print "No rows returned from date query\n";
			print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
		} else {
# Does our date look valid?
			if($SUBSCRIPTION_DATE eq "0000-00-00 00:00:00") {
# No date provided, so we go to MAILER1
				print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
				next;
			}
			if($SUBSCRIPTION_DATE =~ /(20\d\d)-(\d\d)-\d\d\s\d\d:\d\d:\d\d$/) {
				#print "Good hit for year: $SUBSCRIPTION_YEAR\n";
				$SUBSCRIPTION_YEAR = $1;
				$SUBSCRIPTION_MONTH = $2;
# fix dates like 06 to read 6 for numeric comparison
				if($SUBSCRIPTION_MONTH =~ /0(\d)/) {
					$SUBSCRIPTION_MONTH = $1;
				}
				if($SUBSCRIPTION_YEAR == "2011") {
					print MAILER15 "$EMAIL\t$SUBSCRIBER\n";
				} elsif ($SUBSCRIPTION_YEAR == "2010") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER13 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER14 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2009") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER11 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER12 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2008") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER9 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER10 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2007") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER7 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER8 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2006") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER5 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER6 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2005") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER3 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER4 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR <= "2004") {
						print MAILER2 "$EMAIL\t$SUBSCRIBER\n";
				}
			} else {
# Something went wrong, so dump it in 'MAILER1'
					print "Miss on Year: $SUBSCRIPTION_DATE\n";
					print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
			}
		}
	}
}

# early 2010 activity
print "Sub-sorting early 2010 by subscription date.\n";
while(<P1_2010_RO>) {
	chomp;
	if($_ =~ /.+\@.+\..+\t\d\d+/) {
		($EMAIL,$SUBSCRIBER) = split(/\t/);
# Every email address should go in master.txt, as other mailing scripts depend on it
		print MASTER "$EMAIL\t$SUBSCRIBER\n";
# Sort by date subscribed
		$sth = $dbh->prepare($SORT_BY_SUBSCRIPTION_QUERY);
		$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
		$SUBSCRIPTION_DATE = $sth->fetchrow();
		if($sth->rows == 0) {
# User has no subscription Date, so dump it in 'MAILER1'
			print "No rows returned from date query\n";
			print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
		} else {
# Does our date look valid?
			if($SUBSCRIPTION_DATE eq "0000-00-00 00:00:00") {
# No date provided, so we go to MAILER1
				print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
				next;
			}
			if($SUBSCRIPTION_DATE =~ /(20\d\d)-(\d\d)-\d\d\s\d\d:\d\d:\d\d$/) {
				#print "Good hit for year: $SUBSCRIPTION_YEAR\n";
				$SUBSCRIPTION_YEAR = $1;
				$SUBSCRIPTION_MONTH = $2;
# fix dates like 06 to read 6 for numeric comparison
				if($SUBSCRIPTION_MONTH =~ /0(\d)/) {
					$SUBSCRIPTION_MONTH = $1;
				}
				if($SUBSCRIPTION_YEAR == "2011") {
					print MAILER15 "$EMAIL\t$SUBSCRIBER\n";
				} elsif ($SUBSCRIPTION_YEAR == "2010") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER13 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER14 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2009") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER11 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER12 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2008") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER9 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER10 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2007") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER7 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER8 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2006") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER5 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER6 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2005") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER3 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER4 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR <= "2004") {
						print MAILER2 "$EMAIL\t$SUBSCRIBER\n";
				}
			} else {
# Something went wrong, so dump it in 'MAILER1'
					print "Miss on Year: $SUBSCRIPTION_DATE\n";
					print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
			}
		}
	}
}

# late 2009 activity
print "Sub-sorting late 2009 by subscription date.\n";
while(<P2_2009_RO>) {
	chomp;
	if($_ =~ /.+\@.+\..+\t\d\d+/) {
		($EMAIL,$SUBSCRIBER) = split(/\t/);
# Every email address should go in master.txt, as other mailing scripts depend on it
		print MASTER "$EMAIL\t$SUBSCRIBER\n";
# Sort by date subscribed
		$sth = $dbh->prepare($SORT_BY_SUBSCRIPTION_QUERY);
		$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
		$SUBSCRIPTION_DATE = $sth->fetchrow();
		if($sth->rows == 0) {
# User has no subscription Date, so dump it in 'MAILER1'
			print "No rows returned from date query\n";
			print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
		} else {
# Does our date look valid?
			if($SUBSCRIPTION_DATE eq "0000-00-00 00:00:00") {
# No date provided, so we go to MAILER1
				print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
				next;
			}
			if($SUBSCRIPTION_DATE =~ /(20\d\d)-(\d\d)-\d\d\s\d\d:\d\d:\d\d$/) {
				#print "Good hit for year: $SUBSCRIPTION_YEAR\n";
				$SUBSCRIPTION_YEAR = $1;
				$SUBSCRIPTION_MONTH = $2;
# fix dates like 06 to read 6 for numeric comparison
				if($SUBSCRIPTION_MONTH =~ /0(\d)/) {
					$SUBSCRIPTION_MONTH = $1;
				}
				if($SUBSCRIPTION_YEAR == "2011") {
					print MAILER15 "$EMAIL\t$SUBSCRIBER\n";
				} elsif ($SUBSCRIPTION_YEAR == "2010") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER13 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER14 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2009") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER11 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER12 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2008") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER9 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER10 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2007") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER7 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER8 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2006") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER5 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER6 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2005") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER3 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER4 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR <= "2004") {
						print MAILER2 "$EMAIL\t$SUBSCRIBER\n";
				}
			} else {
# Something went wrong, so dump it in 'MAILER1'
					print "Miss on Year: $SUBSCRIPTION_DATE\n";
					print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
			}
		}
	}
}

# No activity group 
print "Populating files subscribers with no known activity.\n";
while(<DEADBEATS_RO>) {
	chomp;
	if($_ =~ /.+\@.+\..+\t\d\d+/) {
		($EMAIL,$SUBSCRIBER) = split(/\t/);
# Every email address should go in master.txt, as other mailing scripts depend on it
		print MASTER "$EMAIL\t$SUBSCRIBER\n";
# Sort by date subscribed
		$sth = $dbh->prepare($SORT_BY_SUBSCRIPTION_QUERY);
		$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
		$SUBSCRIPTION_DATE = $sth->fetchrow();
		if($sth->rows == 0) {
# User has no subscription Date, so dump it in 'MAILER1'
			print "No rows returned from date query\n";
			print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
		} else {
# Does our date look valid?
			if($SUBSCRIPTION_DATE eq "0000-00-00 00:00:00") {
# No date provided, so we go to MAILER1
				print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
				next;
			}
			if($SUBSCRIPTION_DATE =~ /(20\d\d)-(\d\d)-\d\d\s\d\d:\d\d:\d\d$/) {
				#print "Good hit for year: $SUBSCRIPTION_YEAR\n";
				$SUBSCRIPTION_YEAR = $1;
				$SUBSCRIPTION_MONTH = $2;
# fix dates like 06 to read 6 for numeric comparison
				if($SUBSCRIPTION_MONTH =~ /0(\d)/) {
					$SUBSCRIPTION_MONTH = $1;
				}
				if($SUBSCRIPTION_YEAR == "2011") {
					print MAILER15 "$EMAIL\t$SUBSCRIBER\n";
				} elsif ($SUBSCRIPTION_YEAR == "2010") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER13 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER14 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2009") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER11 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER12 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2008") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER9 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER10 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2007") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER7 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER8 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2006") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER5 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER6 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR == "2005") {
					if($SUBSCRIPTION_MONTH <= "6") {
						print MAILER3 "$EMAIL\t$SUBSCRIBER\n";
					} elsif($SUBSCRIPTION_MONTH >= "7") {
						print MAILER4 "$EMAIL\t$SUBSCRIBER\n";
					} else {
						print "Cannot find a date for $EMAIL\t$SUBSCRIBER : $SUBSCRIPTION_YEAR - $SUBSCRIPTION_MONTH\n";
					}
				} elsif ($SUBSCRIPTION_YEAR <= "2004") {
						print MAILER2 "$EMAIL\t$SUBSCRIBER\n";
				}
			} else {
# Something went wrong, so dump it in 'MAILER1'
					print "Miss on Year: $SUBSCRIPTION_DATE\n";
					print MAILER1 "$EMAIL\t$SUBSCRIBER\n";
			}
		}
	}
}

## In case we have mroe themn one mailing, we might want to create a supression list
## See https://trac.shermanstravel.com/wiki/EmailProcess
## sudo /bin/cat /home/mking/bin/mailfiles/master.txt | /bin/awk '{print $1}' > /home/gwhalen/suppression/spamtrap_suppression-`/bin/date +%F`
## Then as gwhalen on queue: /home/gwhalen/bin/suppression_list.pl -l /home/gwhalen/suppression/spamtrap_segment-`/bin/date +%F` -t spamtrap_suppression_`/bin/date +%F` -T line

# Close out open files:
close(MASTER);
close(MAILER1);
close(MAILER2);
close(MAILER3);
close(MAILER4);
close(MAILER5);
close(MAILER6);
close(MAILER7);
close(MAILER8);
close(MAILER9);
close(MAILER10);
close(MAILER11);
close(MAILER12);
close(MAILER13);
close(MAILER14);
close(MAILER15);
close(COREG_RO);
close(RECENT_RO);
close(P1_2011_RO);
close(P2_2010_RO);
close(P1_2010_RO);
close(P2_2009_RO);
close(DEADBEATS_RO);

# Finally close out our DB connections
$sth->finish();
$dbh->disconnect();
