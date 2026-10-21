#!/usr/bin/perl

use strict;
use warnings;
require DBD::mysql;

###########
# Trac #6713
#
#Given an range of user ID's we need to look through the click database and determine how many clicks on Top25, ROS, and bulletins were made by that user by month.
#
# The output should be in the following format. One csv file should just list out:
# userID
# YY-MM
# Top25 clicks that month
# ROS clicks that month
# bulletin clicks that month
#
# The second csv file should list out the numbers above but tallied across all users in the given range by month.
# YY-MM
# Top25 clicks that month
# ROS clicks that month
# bulletin clicks that month
###########
#
# Update 07/13/11
# Categories are now Top25, Non-Top25-Newsletters and Bulletins
#

# General variables
#my $START_DATE = '2010-01-01 00:00:00';
#my $END_DATE = '2010-01-14 23:59:59';
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

my @PEOPLE_DATA;
my @PERSON_ID_LIST;
my @NEWSLETTER_MAILINGS;
my @NEWSLETTER_TOP25_ID_LIST;
my @NEWSLETTER_NONTOP25_ID_LIST;
my @BULLETIN_MAILINGS;
my @BULLETIN_ID_LIST;
my $BULLETIN_CLICKS;
my $TOP25_CLICKS;
my $NEWSLETTER_NONTOP25_CLICKS;
my $PERSON_ID;
my @CAMPAIGN_CLICKS_BY_USER;
my $CAMPAIGN_DATE;
my $CAMPAIGN_DATE_DAY;
my $CAMPAIGN_DATE_MONTH;
my $CAMPAIGN_DATE_TIME;
my $CAMPAIGN_CLICKS;
my $CAMPAIGN_NAME;
my @CAMPAIGN_CLICKS_BY_DATE;

# st.newsletter_deal_clicks
my $NDC_ID;
my $NDC_DEAL_ID;
my $NDC_REVENUE;
my $NDC_PERSON_ID;					# Hopefully matches id in st.people
my $NDC_MAILING_CAMPAIGN_ID;		# Should match st.mailing_campaigns.id
my $NDC_CAMPAIGN_POSTITION;
my $NDC_CREATED;
my $NDC_MODIFIED;

# st.advertiser_link_clicks
my $ALC_ID;
my $ALC_ADVERTISER_LINK_ID;
my $ALC_PERSON_ID;					# Hopefully matches id in st.people
my $ALC_MAILING_CAMPAIGN_ID;		# Should match st.mailing_campaigns.id
my $ALC_CAMPAIGN_POSTITION;
my $ALC_CREATED;
my $ALC_MODIFIED;

# st.mailing_campaigns
my $MC_ID;							# Should Correspond to st.newsletter_deal_clicks.mailing_campaign_id
my $MC_NAME;						# Text field for Title of mailing
my $MC_MAILING_ID;
my $MC_CREATED;
my $MC_MODIFIED;

# MYSQL queries and Updates.
# We will not need the people query, as one would assume that Mark will give me IDs
# But for now, lets just grab a sample
my $PERSON_ID_QUERY = "SELECT DISTINCT person_id FROM newsletter_deal_clicks ORDER BY RAND() LIMIT 10";
my $NEWSLETTER_CLICKS_BY_PERSON_QUERY = "SELECT ndc.person_id, ndc.modified, mc.name, COUNT(ndc.person_id) FROM newsletter_deal_clicks AS ndc, mailing_campaigns AS mc WHERE ndc.mailing_campaign_id=mc.id AND ndc.person_id = ? GROUP BY DATE(ndc.created)";
my $BULLETIN_CLICKS_BY_PERSON_QUERY = "SELECT alc.person_id, alc.modified, mc.name, COUNT(alc.person_id) FROM advertiser_link_clicks AS alc, mailing_campaigns AS mc WHERE alc.mailing_campaign_id=mc.id AND alc.person_id = ? GROUP BY DATE(alc.created)";
#my $NEWSLETTER_CLICKS_BY_DATE_QUERY = "SELECT ndc.modified, mc.name, COUNT(ndc.person_id) FROM newsletter_deal_clicks AS ndc, mailing_campaigns AS mc WHERE ndc.mailing_campaign_id=mc.id AND mc.id = ? GROUP BY DATE(mc.id)";
#my $BULLETIN_CLICKS_BY_DATE_QUERY = "SELECT alc.modified, mc.name, COUNT(alc.person_id) FROM advertiser_link_clicks AS alc, mailing_campaigns AS mc WHERE mc.id = ? AND alc.mailing_campaign_id=mc.id GROUP BY DATE(mc.id)";

#my $NEWSLETTER_QUERY = "SELECT id, name FROM mailing_campaigns WHERE name LIKE '%NewsLetter%'";
#my $PERSONS_NEWSLETTER_QUERY = "SELECT id, name FROM mailing_campaigns WHERE name LIKE '%NewsLetter%'";
#my $BULLETIN_QUERY = "SELECT id FROM mailing_campaigns WHERE name LIKE '%Bulletin%'";
#my $TOTAL_QUERY = "SELECT COUNT(*) FROM newsletter_deal_clicks WHERE mailing_campaign_id = ?";
#my $CLICKS_BY_CAMPAIGN_QUERY = "SELECT COUNT(*) FROM newsletter_deal_clicks WHERE mailing_campaign_id = ?";
#my $CLICKS_BY_CAMPAIGN_AND_PERSON_QUERY = "SELECT COUNT(*) FROM newsletter_deal_clicks WHERE person_id = ? AND  mailing_campaign_id = ?";
# Grab what campaigns and clicks per campaign by person_id
# SELECT mailing_campaign_id, COUNT(mailing_campaign_id), modified FROM newsletter_deal_clicks WHERE person_id = "13408199" GROUP BY mailing_campaign_id ORDER BY modified;
#my $NEWSLETTER_CLICKS_BY_PERSON = "SELECT ndc.person_id, ndc.modified, COUNT(ndc.person_id) FROM newsletter_deal_clicks AS ndc, mailing_campaigns AS mc WHERE ndc.mailing_campaign_id=mc.id AND ndc.person_id = ? AND mc.name LIKE '%NewsLetter%' AND ndc.created BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 MONTH) AND CURDATE() GROUP BY DATE(ndc.created)";
#my $BULLETIN_CLICKS_BY_PERSON = "SELECT ndc.person_id, ndc.modified, COUNT(ndc.person_id) FROM newsletter_deal_clicks AS ndc, mailing_campaigns AS mc WHERE ndc.mailing_campaign_id=mc.id AND ndc.person_id = ? AND mc.name LIKE '%Bulletin%' AND ndc.created BETWEEN DATE_SUB(CURDATE(), INTERVAL 1 MONTH) AND CURDATE() GROUP BY DATE(ndc.created)";


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

# Choose some people
$STH = $DBH->prepare($PERSON_ID_QUERY);
$STH->execute() or die "Couldn't execute statement: " . $STH->errstr;
# Put results an array for use later
while (@PEOPLE_DATA = $STH->fetchrow_array()) {
		$NDC_PERSON_ID = $PEOPLE_DATA[0];
		unless($NDC_PERSON_ID == '0') {
			push(@PERSON_ID_LIST,$NDC_PERSON_ID);
		}
}

# Table #1
print "'ID','DATE','TOP25 CLICKS',' NEWSLETTER CLICKS','BULLETIN CLICKS'\n";
foreach $PERSON_ID (@PERSON_ID_LIST) {
	$STH = $DBH->prepare($NEWSLETTER_CLICKS_BY_PERSON_QUERY);
	$STH->execute($PERSON_ID) or die "Couldn't execute statement: " . $STH->errstr;
	while (@CAMPAIGN_CLICKS_BY_USER = $STH->fetchrow_array()) {
# Reset Counters
		$BULLETIN_CLICKS = '0';
		$TOP25_CLICKS = '0';
		$NEWSLETTER_NONTOP25_CLICKS = '0';
# Now to make sense of the row we just fetched
		$PERSON_ID = $CAMPAIGN_CLICKS_BY_USER[0];
		$CAMPAIGN_DATE = $CAMPAIGN_CLICKS_BY_USER[1];
		$CAMPAIGN_NAME = $CAMPAIGN_CLICKS_BY_USER[2];
		$CAMPAIGN_CLICKS = $CAMPAIGN_CLICKS_BY_USER[3];
#O.K.  Now we pretty much have to process everything
# $PERSON_ID is fine as is
# $CAMPAIGN_DATE need to have Day and time separate 
		if($CAMPAIGN_DATE =~ /((\d\d\d\d-\d\d)-\d\d)\s(\d\d:\d\d:\d\d)/) {
			$CAMPAIGN_DATE_DAY = $1;
			$CAMPAIGN_DATE_MONTH = $2;
			$CAMPAIGN_DATE_TIME = $3;
		} else {
# If date is invalid, no need to record it.
			$CAMPAIGN_DATE_DAY = 'unknown';
			$CAMPAIGN_DATE_MONTH = 'unknown';
			$CAMPAIGN_DATE_TIME = 'unknown';
		}
# $CAMPAIGN_NAME needs to be broken up into categories
# So I can make sense of $CAMPAIGN_CLICKS
			#print "Looking for: $CAMPAIGN_NAME\n";
		if($CAMPAIGN_NAME =~ /Top\s25/) {
			$TOP25_CLICKS = $TOP25_CLICKS+$CAMPAIGN_CLICKS;
		} else {
			#print "---Non-Top25 Newsletter: $CAMPAIGN_NAME\n";
			$NEWSLETTER_NONTOP25_CLICKS = $NEWSLETTER_NONTOP25_CLICKS+$CAMPAIGN_CLICKS;
		}
		print "'$PERSON_ID','$CAMPAIGN_DATE_DAY','$TOP25_CLICKS','$NEWSLETTER_NONTOP25_CLICKS','$BULLETIN_CLICKS'\n";
	}
	$STH = $DBH->prepare($BULLETIN_CLICKS_BY_PERSON_QUERY);
	$STH->execute($PERSON_ID) or die "Couldn't execute statement: " . $STH->errstr;
	while (@CAMPAIGN_CLICKS_BY_USER = $STH->fetchrow_array()) {
# Reset Counters
		$BULLETIN_CLICKS = '0';
		$TOP25_CLICKS = '0';
		$NEWSLETTER_NONTOP25_CLICKS = '0';
# Now to make sense of the row we just fetched
		$PERSON_ID = $CAMPAIGN_CLICKS_BY_USER[0];
		$CAMPAIGN_DATE = $CAMPAIGN_CLICKS_BY_USER[1];
		$CAMPAIGN_NAME = $CAMPAIGN_CLICKS_BY_USER[2];
		$CAMPAIGN_CLICKS = $CAMPAIGN_CLICKS_BY_USER[3];
#O.K. We need to process a few things in the output.
# $PERSON_ID is fine as is
# $CAMPAIGN_DATE need to have Day and time separate 
		if($CAMPAIGN_DATE =~ /((\d\d\d\d-\d\d)-\d\d)\s(\d\d:\d\d:\d\d)/) {
			$CAMPAIGN_DATE_DAY = $1;
			$CAMPAIGN_DATE_MONTH = $1;
			$CAMPAIGN_DATE_TIME = $3;
		} else {
# If date is invalid, no need to record it.
			$CAMPAIGN_DATE_DAY = 'unknown';
			$CAMPAIGN_DATE_MONTH = 'unknown';
			$CAMPAIGN_DATE_TIME = 'unknown';
		}
# Only one type of campaign here, Bulletins.
		$BULLETIN_CLICKS = $BULLETIN_CLICKS+$CAMPAIGN_CLICKS;
		print "'$PERSON_ID','$CAMPAIGN_DATE_DAY','$TOP25_CLICKS','$NEWSLETTER_NONTOP25_CLICKS','$BULLETIN_CLICKS'\n";
	}
}

## Table #2
#print "'DATE','TOP25 CLICKS',' NEWSLETTER CLICKS','BULLETIN CLICKS'\n";
#foreach $CAMPAIGN_DATE (@CAMPAIGN_DATE_LIST) {
#	$STH = $DBH->prepare($NEWSLETTER_CLICKS_BY_DATE_QUERY);
#	$STH->execute($CAMPAIGN_DATE) or die "Couldn't execute statement: " . $STH->errstr;
#	while (@CAMPAIGN_CLICKS_BY_DATE = $STH->fetchrow_array()) {
## Reset Counters
#		$BULLETIN_CLICKS = '0';
#		$TOP25_CLICKS = '0';
#		$NEWSLETTER_NONTOP25_CLICKS = '0';
## Now to make sense of the row we just fetched
#		$CAMPAIGN_DATE = $CAMPAIGN_CLICKS_BY_DATE[0];
#		$CAMPAIGN_NAME = $CAMPAIGN_CLICKS_BY_DATE[1];
#		$CAMPAIGN_CLICKS = $CAMPAIGN_CLICKS_BY_DATE[2];
##O.K. We need to process a few things in the output.
## $CAMPAIGN_DATE need to have Day and time separate 
#		if($CAMPAIGN_DATE =~ /(\d\d\d\d-\d\d-\d\d)\s(\d\d:\d\d:\d\d)/) {
#			$CAMPAIGN_DATE_DAY = $1;
#			$CAMPAIGN_DATE_TIME = $1;
#		} 
## $CAMPAIGN_NAME needs to be broken up into categories
# So I can make sense of $CAMPAIGN_CLICKS
#			#print "Looking for: $CAMPAIGN_NAME\n";
#		if($CAMPAIGN_NAME =~ /Top\s25/) {
#			$TOP25_CLICKS = $TOP25_CLICKS+$CAMPAIGN_CLICKS;
#		} else {
#			#print "---Non-Top25 Newsletter: $CAMPAIGN_NAME\n";
#			$NEWSLETTER_NONTOP25_CLICKS = $NEWSLETTER_NONTOP25_CLICKS+$CAMPAIGN_CLICKS;
#		}
#		print "'$CAMPAIGN_DATE_DAY','$TOP25_CLICKS','$NEWSLETTER_NONTOP25_CLICKS','$BULLETIN_CLICKS'\n";
#	}
#	$STH = $DBH->prepare($BULLETIN_CLICKS_BY_DATE_QUERY);
#	$STH->execute($CAMPAIGN_DATE) or die "Couldn't execute statement: " . $STH->errstr;
#	while (@CAMPAIGN_CLICKS_BY_DATE = $STH->fetchrow_array()) {
## Reset Counters
#		$BULLETIN_CLICKS = '0';
#		$TOP25_CLICKS = '0';
#		$NEWSLETTER_NONTOP25_CLICKS = '0';
## Now to make sense of the row we just fetched
#		$CAMPAIGN_DATE = $CAMPAIGN_CLICKS_BY_DATE[0];
#		$CAMPAIGN_NAME = $CAMPAIGN_CLICKS_BY_DATE[1];
#		$CAMPAIGN_CLICKS = $CAMPAIGN_CLICKS_BY_DATE[2];
## O.K. We need to process a few things in the output.
## $CAMPAIGN_DATE need to have Day and time separate 
#		if($CAMPAIGN_DATE =~ /(\d\d\d\d-\d\d-\d\d)\s(\d\d:\d\d:\d\d)/) {
#			$CAMPAIGN_DATE_DAY = $1;
#			$CAMPAIGN_DATE_TIME = $1;
#		} 
## Only one type of campaign here, Bulletins.
#		$BULLETIN_CLICKS = $BULLETIN_CLICKS+$CAMPAIGN_CLICKS;
#		print "'$CAMPAIGN_DATE_DAY','$TOP25_CLICKS','$NEWSLETTER_NONTOP25_CLICKS','$BULLETIN_CLICKS'\n";
#	}
#}
