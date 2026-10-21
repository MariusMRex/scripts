#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## To find spam traps we need to sort users by last time they
## interacted with a mailing
## Marius 2011-10-19

## O.K.  Lets say we broke people up into 8 categories
## essentially 6 month buckets.  There are 8 odd numbers
## between 1-15 (1,3,5,7,9,11,13,15) So we put each of
## six groups into a mailer bucket.
##
## Now we do an intial query to get person_ids from derived address
## that filters out the inactives, and runs whatever logic
## The current mailing needs. Then we break people up into
## The eight categories in the order of last click or open.
##
## The earliest click data we have in  newsletter_deal_clicks is 2009-08-17 16:34:31
## The earliest open we have recorded in mailing_campaign_opens is 2009-09-01 13:03:42

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

my $SUBSCRIBER;
my @SUBSCRIBER_LIST;
my $PERSON_ID;
my $EMAIL;
my $DMA;
my @PEOPLE_LIST;
my @CURRENT_SUBSCRIBER_LIST;
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
my $TOTAL_ACTIVE_SUBSCRIBERS = "0";
my $LOST_COUNT = "0";
my @RECENT_LIST;
my @P1_2011_LIST;
my @P2_2010_LIST;
my @P1_2010_LIST;
my @P2_2009_LIST;
my @REMAINDER_LIST;
my @DMA_SORT_LIST;

my $MAILER;
my $EST;
my $CST;
my $MST;
my $PST;

# MYSQL queries and Updates.
my $SUBSCRIBER_QUERY = "SELECT person_id FROM derived_address ORDER BY RAND() LIMIT 1000";
#my $SUBSCRIBER_QUERY = "SELECT person_id FROM derived_address WHERE person_id NOT IN(SELECT person_id FROM inactive_10_19_2011_tmp) ORDER BY created";
#my $SUBSCRIBER_QUERY = "SELECT person_id FROM derived_address AS d WHERE person_id NOT IN(SELECT person_id FROM inactive_10_19_2011_tmp) AND ((d.active='Y' AND d.subscr_bulletin='Y') AND ((d.spec_interest_cruise = 'Y')) OR d.person_id IN(SELECT person_id FROM derived_address AS d WHERE d.subscr_bulletin='Y' AND d.active='Y')) LIMIT 2400000";
my $RECENT_CLICK_QUERY = "SELECT person_id FROM newsletter_deal_clicks WHERE person_id = ? AND modified BETWEEN '2011-07-01 00:00:00' AND NOW() LIMIT 1";
my $RECENT_OPEN_QUERY = "SELECT person_id  FROM mailing_campaign_opens WHERE person_id = ? AND modified BETWEEN '2011-07-01 00:00:00' AND NOW() LIMIT 1";
my $P1_2011_CLICK_QUERY = "SELECT person_id FROM newsletter_deal_clicks WHERE person_id = ? AND modified BETWEEN '2011-01-01 00:00:00' AND '2011-06-31 23:59:59' LIMIT 1";
my $P1_2011_OPEN_QUERY = "SELECT person_id FROM mailing_campaign_opens WHERE person_id = ? AND modified BETWEEN '2011-01-01 00:00:00' AND '2011-06-31 23:59:59' LIMIT 1";
my $P2_2010_CLICK_QUERY = "SELECT person_id FROM newsletter_deal_clicks WHERE person_id = ? AND modified BETWEEN '2010-07-01 00:00:00' AND '2010-12-31 23:59:59' LIMIT 1"; 
my $P2_2010_OPEN_QUERY = "SELECT person_id FROM mailing_campaign_opens WHERE person_id = ? AND modified BETWEEN '2010-07-01 00:00:00' AND '2010-12-31 23:59:59' LIMIT 1";
my $P1_2010_CLICK_QUERY = "SELECT person_id FROM newsletter_deal_clicks WHERE person_id = ? AND modified BETWEEN '2010-01-01 00:00:00' AND '2010-06-31 23:59:59' LIMIT 1";
my $P1_2010_OPEN_QUERY = "SELECT person_id FROM mailing_campaign_opens WHERE person_id = ? AND modified BETWEEN '2010-01-01 00:00:00' AND '2010-06-31 23:59:59' LIMIT 1";
my $P2_2009_CLICK_QUERY = "SELECT person_id FROM newsletter_deal_clicks WHERE person_id = ? AND modified BETWEEN '2009-07-01 00:00:00' AND '2009-12-31 23:59:59' LIMIT 1";
my $P2_2009_OPEN_QUERY = "SELECT person_id FROM mailing_campaign_opens WHERE person_id = ? AND modified BETWEEN '2009-07-01 00:00:00' AND '2009-12-31 23:59:59' LIMIT 1";
# We have no click or open data from before August of 2009
my $NOT_ACTIVE_QUERY = "SELECT email FROM people WHERE id = ?";
my $DMA_SORT_QUERY = "SELECT email, person_id, derived_dma FROM derived_address WHERE person_id = ?";

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
print "Lets grab the list of people from derived_address.\n";
$sth = $dbh->prepare($SUBSCRIBER_QUERY);
$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
while (@PEOPLE_LIST = $sth->fetchrow_array()) {
	$SUBSCRIBER = $PEOPLE_LIST[0];
	push(@CURRENT_SUBSCRIBER_LIST,$SUBSCRIBER);
	#print "*";
	++$TOTAL_ACTIVE_SUBSCRIBERS;
}
print "Total Active Subscribers Found: $TOTAL_ACTIVE_SUBSCRIBERS\n";

# Lets create a directory, to stick mail files into, if it does not already exist
unless(-d "./mailfiles") {
	mkdir("mailfiles",0777) || die "Cannot mkdir mailfiles: $!";
}

# Lets open some mail files for writing to in our special directory
open(RECENT, ">mailfiles/mailer1.txt");
open(P1_2011, ">mailfiles/mailer4.txt");
open(P2_2010, ">mailfiles/mailer7.txt");
open(P1_2010, ">mailfiles/mailer10.txt");
open(P2_2009, ">mailfiles/mailer13.txt");
open(DEADBEATS, ">mailfiles/mailer15.txt");

# Recent Interaction
print "Looking for recent clicks\n";
foreach $SUBSCRIBER(@CURRENT_SUBSCRIBER_LIST) {
	#print "Subscriber is $SUBSCRIBER\n";
	$sth = $dbh->prepare($RECENT_CLICK_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they clicked, so we will put them in the mail file
	# and remove their name from further selection.
	$PERSON_ID = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_RECENT,$PERSON_ID);
	} else {
		print RECENT "$PERSON_ID\n";
		push(@RECENT_LIST,$PERSON_ID);
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for recent opens\n";
foreach $SUBSCRIBER(@NO_CLICK_RECENT) {
	$sth = $dbh->prepare($RECENT_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$PERSON_ID = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_RECENT,$PERSON_ID);
	} else {
		print RECENT "$PERSON_ID\n";
		push(@RECENT_LIST,$PERSON_ID);
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
	$PERSON_ID = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P1_2011,$PERSON_ID);
	} else {
		push(@P1_2011_LIST,$PERSON_ID);
		print P1_2011 "$PERSON_ID\n";
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for opens 2011 p1\n";
foreach $SUBSCRIBER(@NO_CLICK_P1_2011) {
	$sth = $dbh->prepare($P1_2011_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$PERSON_ID = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P1_2011,$PERSON_ID);
	} else {
		push(@P1_2011_LIST,$PERSON_ID);
		print P1_2011 "$PERSON_ID\n";
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
	$PERSON_ID = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P2_2010,$PERSON_ID);
	} else {
		push(@P2_2010_LIST,$PERSON_ID);
		print P2_2010 "$PERSON_ID\n";
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for opens 2010 p2\n";
foreach $SUBSCRIBER(@NO_CLICK_P2_2010) {
	$sth = $dbh->prepare($P2_2010_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$PERSON_ID = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P2_2010,$PERSON_ID);
	} else {
		push(@P2_2010_LIST,$PERSON_ID);
		print P2_2010 "$PERSON_ID\n";
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
	$PERSON_ID = $sth->fetchrow();
	if($sth->rows == 0) {
		print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P1_2010,$PERSON_ID);
	} else {
		push(@P1_2010_LIST,$PERSON_ID);
		print P1_2010 "$PERSON_ID\n";
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for opens 2010 p1\n";
foreach $SUBSCRIBER(@NO_CLICK_P1_2010) {
	$sth = $dbh->prepare($P1_2010_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$PERSON_ID = $sth->fetchrow();
	if($sth->rows == 0) {
		print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_OPEN_P1_2010,$PERSON_ID);
	} else {
		push(@P1_2010_LIST,$PERSON_ID);
		print P1_2010 "$PERSON_ID\n";
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
	$PERSON_ID = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
		push(@NO_CLICK_P2_2009,$PERSON_ID);
	} else {
		push(@P2_2009_LIST,$PERSON_ID);
		print P2_2009 "$PERSON_ID\n";
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}
print "Looking for opens 2009 p2\n";
foreach $SUBSCRIBER(@NO_CLICK_P2_2009) {
	$sth = $dbh->prepare($P2_2009_OPEN_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they registered an 'open' in our database, so we put them in a mail file
	# and remove their name from further selection.
	$PERSON_ID = $sth->fetchrow();
	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
# These folks seem to have no clicks
		push(@REMAINDER_LIST,$PERSON_ID);
	} else {
		push(@P2_2009_LIST,$PERSON_ID);
		print P2_2009 "$PERSON_ID\n";
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}

# All that is left is people who do not seem to click or open
print "And now the folks who do not interact at all it seems...\n";
foreach $SUBSCRIBER(@REMAINDER_LIST) {
		$sth = $dbh->prepare($NOT_ACTIVE_QUERY);
		$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
# Any ids we have left appearently did not have any clicks or opens we could find.
# Lets give them their own mailfile.
		$EMAIL = $sth->fetchrow();
		if($sth->rows == 0) {
			++$LOST_COUNT;
		} else {
			print DEADBEATS "$EMAIL\t$SUBSCRIBER\n";
		}
}

# Now we have a whole bunch of lists, and we want to write out 
# Location based files.

# Recent Subscribers
$MAILER = "1";
open(EST, ">mailfiles/est1.txt");
open(CST, ">mailfiles/cst1.txt");
open(MST, ">mailfiles/mst1.txt");
open(PST, ">mailfiles/pst1.txt");
print "Segmenting for mailer$MAILER\n";
foreach $SUBSCRIBER(@RECENT_LIST){
	#print "$SUBSCRIBER -";
	$sth = $dbh->prepare($DMA_SORT_QUERY);
	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
	while (@DMA_SORT_LIST = $sth->fetchrow_array()) {
		$EMAIL = $DMA_SORT_LIST[0];
		$PERSON_ID = $DMA_SORT_LIST[1];
		$DMA = $DMA_SORT_LIST[2];
		#print "MAILER1: $EMAIL, $PERSON_ID, $DMA\n";
		if (defined $DMA) {
			if ($DMA >= 500 && $DMA < 600) {
				print EST "$EMAIL\t$PERSON_ID\n";
				#$tz{'est'}++;
			}
			if ($DMA >= 600 && $DMA < 700) {
				print CST "$EMAIL\t$PERSON_ID\n";
				#$tz{'cst'}++
			}
			if ($DMA >= 700 && $DMA < 800) {
				print MST "$EMAIL\t$PERSON_ID\n";
				#$tz{'mst'}++;
			}
			if ($DMA >= 800 && $DMA < 900) {
				print PST "$EMAIL\t$PERSON_ID\n";
				#$tz{'pst'}++;
			}
			if ($DMA == 0) {
				print PST "$EMAIL\t$PERSON_ID\n";
				#$tz{'unk'}++;
			}
		}
	}
}
close(EST);
close(CST);
close(MST);
close(PST);

# Early 2011
$MAILER = "4";
print "Segmenting for mailer$MAILER\n";
foreach $SUBSCRIBER(@P1_2011_LIST){
	sort_by_dma($SUBSCRIBER,$MAILER);
}
# Late 2010
$MAILER = "7";
print "Segmenting for mailer$MAILER\n";
foreach $SUBSCRIBER(@P2_2010_LIST){
	sort_by_dma($SUBSCRIBER,$MAILER);
}
# Early 2010
$MAILER = "10";
print "Segmenting for mailer$MAILER\n";
foreach $SUBSCRIBER(@P1_2010_LIST){
	sort_by_dma($SUBSCRIBER,$MAILER);
}
# Late 2009
$MAILER = "13";
print "Segmenting for mailer$MAILER\n";
foreach $SUBSCRIBER(@P2_2009_LIST){
	sort_by_dma($SUBSCRIBER,$MAILER);
}
# Remainders
$MAILER = "15";
print "Segmenting for mailer$MAILER\n";
foreach $SUBSCRIBER(@REMAINDER_LIST){
	sort_by_dma($SUBSCRIBER,$MAILER);
}

$sth->finish();
$dbh->disconnect();

print "Number of Accounts we could not find: $LOST_COUNT\n";

## Sub-routines

# Sort the DMAs by timezone
sub sort_by_dma {
	#print "$SUBSCRIBER -";
	open(EST, ">mailfiles/est$_[1].txt");
	open(CST, ">mailfiles/cst$_[1].txt");
	open(MST, ">mailfiles/mst$_[1].txt");
	open(PST, ">mailfiles/pst$_[1].txt");
	$sth = $dbh->prepare($DMA_SORT_QUERY);
	$sth->execute($_[0]) or die "Couldn't execute statement: " . $sth->errstr;
	while (@DMA_SORT_LIST = $sth->fetchrow_array()) {
		$EMAIL = $DMA_SORT_LIST[0];
		$PERSON_ID = $DMA_SORT_LIST[1];
		$DMA = $DMA_SORT_LIST[2];
		print "Mailer $MAILER: $EMAIL, $PERSON_ID, $DMA\n";
		if (defined $DMA) {
			if ($DMA >= 500 && $DMA < 600) {
				print EST "$EMAIL\t$PERSON_ID\n";
				#$tz{'est'}++;
			}
			if ($DMA >= 600 && $DMA < 700) {
				print CST "$EMAIL\t$PERSON_ID\n";
				#$tz{'cst'}++
			}
			if ($DMA >= 700 && $DMA < 800) {
				print MST "$EMAIL\t$PERSON_ID\n";
				#$tz{'mst'}++;
			}
			if ($DMA >= 800 && $DMA < 900) {
				print PST "$EMAIL\t$PERSON_ID\n";
				#$tz{'pst'}++;
			}
			if ($DMA == 0) {
				print PST "$EMAIL\t$PERSON_ID\n";
				#$tz{'unk'}++;
			}
		}
	}
	close(EST);
	close(CST);
	close(MST);
	close(PST);
}

