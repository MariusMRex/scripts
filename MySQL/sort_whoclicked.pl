#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

#
# Local Deals went out yesterday, but dealcurrent went down.
# Can we find who clicked and get their info to re-mail them?
#
# SELECT COUNT(*) FROM advertiser_link_clicks WHERE mailing_campaign_id = "8611" AND created < "2012-03-15 13:00:00"
# In this case I happen to know that there should only be 500 or so clicks in the time period, so there is
# no need to slpit ito multiple mail files.

my $MAIL_FILES_HOME = "/home/mking/marii_bin/mailfiles/";
my $SOURCE_FILE = "local_deals_nyc_03_15_2012.txt";
my $OUTFILE = "click_local_deals_nyc_03_15_2012.txt";
my $MAIL_LIST = "$MAIL_FILES_HOME$SOURCE_FILE";
my $MAIL_OUT_LIST = "$MAIL_FILES_HOME$OUTFILE";
my $MAILING_ID = "8611";		
#my $MAILING_ID_1 = "8167";			# st.newsletter_deal_clicks.mailing_campaign_id and st.mailing_campaign_opens.mailing_campaign_id 8167 is the first mailing on 02-01-2012
#my $MAILING_ID_2 = "8172";			# 8172 is a second mailing to yahoo.com on 02-02-2012 We are avoiding both
my $START_DATE = "2012-03-15 12:00:00";
my $END_DATE = "2012-03-15 18:00:01";
my $DB_Database = "st";
my $DB_Host = "10.131.125.94";          # db4 
my $DB_Username = "webuser";
my $DB_Password = "[Redacted]";
my $sth;
my $FATAL_ERROR;
my $ERROR_INFO;
my $EMAIL;
my $PERSON_ID;

# Variables realated to st.subscriptions, but not actually fields in the DB
#my $S_CREATED_START = "$ARGV[0] 00:00:00";	# First Second of date entered at Command Line
#my $S_MODIFIED_END = "$ARGV[1] 23:59:59";	# Last second of date entered at Command Line

#my $CLICKS_QUERY = "SELECT DISTINCT person_id FROM newsletter_deal_clicks WHERE (mailing_campaign_id = ? OR mailing_campaign_id = ?) AND person_id = ?";
#my $OPEN_QUERY = "SELECT DISTINCT person_id FROM mailing_campaign_opens WHERE (mailing_campaign_id = ? OR mailing_campaign_id = ?) AND person_id = ?";
#my $CLICKS_QUERY = "SELECT DISTINCT id FROM advertiser_link_clicks WHERE person_id = ? AND mailing_campaign_id = ? AND created BETWEEN ? AND ? LIMIT 1";
my $CLICKS_QUERY = "SELECT DISTINCT id FROM advertiser_link_clicks WHERE person_id = ? AND mailing_campaign_id = ? AND created BETWEEN ? AND ? GROUP BY person_id";

# Open our mail list for reading
print "Opening up $MAIL_LIST for processing.\n";
open(SOURCE_FILE, "$MAIL_LIST");
open(OUTFILE, ">$MAIL_OUT_LIST");

my $dbh=DBI->connect("DBI:mysql:host=$DB_Host;database=$DB_Database","$DB_Username", "$DB_Password", {PrintError=>0, RaiseError=>0})
	or
	die("Failed connecting to Db4 ". "(error number $DBI::err): $DBI::errstr\n"); 

while(<SOURCE_FILE>) {
	#if(/([\w.%+-]+@[\w.-]+\.[\w]{2,4})\s(\d+) {
	($EMAIL,$PERSON_ID) = split(/\t/);
	chomp($EMAIL);
	chomp($PERSON_ID);
	$sth = $dbh->prepare($CLICKS_QUERY);
	$sth->execute($PERSON_ID,$MAILING_ID,$START_DATE,$END_DATE) or die "Couldn't execute statement: " . $sth->errstr;
	if($sth->rows == 0) {
		print "NoClicky\n";
	} else {
		print OUTFILE "$EMAIL\t$PERSON_ID\n";
		print "$EMAIL\t$PERSON_ID\n";
		#print "Click\n";
	}
}
close(SOURCE_FILE);
close(OUTFILE);

$sth->finish();
$dbh->disconnect();
