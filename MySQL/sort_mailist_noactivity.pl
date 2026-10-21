#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

#  The Top25 mailing for 2012-02-02 only had about 50% of the clicks as normal.
# Folks want to re-send segments of the list in hope that it will go throgh this time.
# (Spamhaus spam traps may have caused some blockage, but we are not sure. Our blacklisting was removed a few hours ago.)
#
# So I have removed all of the aol.com addresses from the master.txt file from 2012-02-02/Top25
# with grep and pushed them into a flat file.
# I now have to process that list, and remove anyone who did open or click that mailing
#
# The plan was to use this script to verify who had clicked or opened, and rule them
# out and then use a modifed version of sort_spam_trappy_addresses_by_number.pl
# To maike the mailer##.txt files.  But that we decided against remailing.
#
# But I imagine I can recycle this script for another occation. 
my $MAIL_FILES_HOME = "/home/mking/marii_bin/mailfiles/";
my $SOURCE_FILE = "aol_addresses_top25_02_01_2012.txt";
my $OUTFILE = "no_click_aol_addresses_top25_02_01_2012.txt";
my $MAIL_LIST = "$MAIL_FILES_HOME$SOURCE_FILE";
my $MAIL_OUT_LIST = "$MAIL_FILES_HOME$OUTFILE";
#my $MAILING_ID = "8167,8172,";		
my $MAILING_ID_1 = "8167";			# st.newsletter_deal_clicks.mailing_campaign_id and st.mailing_campaign_opens.mailing_campaign_id 8167 is the first mailing on 02-01-2012
my $MAILING_ID_2 = "8172";			# 8172 is a second mailing to yahoo.com on 02-02-2012 We are avoiding both
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

my $CLICKS_QUERY = "SELECT DISTINCT person_id FROM newsletter_deal_clicks WHERE (mailing_campaign_id = ? OR mailing_campaign_id = ?) AND person_id = ?";
my $OPEN_QUERY = "SELECT DISTINCT person_id FROM mailing_campaign_opens WHERE (mailing_campaign_id = ? OR mailing_campaign_id = ?) AND person_id = ?";

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
	$sth->execute($MAILING_ID_1,$MAILING_ID_2,$PERSON_ID) or die "Couldn't execute statement: " . $sth->errstr;
	if($sth->rows == 0) {
		$sth = $dbh->prepare($OPEN_QUERY);
		$sth->execute($MAILING_ID_1,$MAILING_ID_2,$PERSON_ID) or die "Couldn't execute statement: " . $sth->errstr;
		if($sth->rows == 0) {
			print OUTFILE "$EMAIL\t$PERSON_ID\n";
			print "NoClicky\n";
		} else {
			print "Open\n";
		}
	} else {
		print "Click\n";
	}
}
close(SOURCE_FILE);
close(OUTFILE);

$sth->finish();
$dbh->disconnect();

