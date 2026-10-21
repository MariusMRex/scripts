#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## Can we write a quick script to comb the deals tables
## and pick out deals?
## Marius 2011-09-14

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

my $KEYWORD;
my $EMAIL;
my @DEALS;
my $FROM_EMAIL = "sysadmin\@shermanstravelmedia.com";
my $DEAL_TYPE;				# This variable will hold whether the deal has an endorsement page
my $STM_URL = "http:\/\/www\.shermanstravel\.com\/";
my $CLICK_TYPE = "3"; 		# When recording this click, attributed it to a website click.  (6 is newsletter)
my $LINK;					# This will be the final finished link
my $MAIL_FILE = "/tmp/deals_search-ID$$";
my $DO_MAIL	= "0";			# Unless this is set to '1' no mail wil go out

if($ARGV[1] =~ /\@shermanstravelmedia.com/) {
	print "Only one Keyword I guess\n";
	$KEYWORD = $ARGV[0];
	$EMAIL = $ARGV[1];
} else {
	print "Multiword key\n";
	$KEYWORD = "$ARGV[0] $ARGV[1]";
	$EMAIL = $ARGV[2];
}


# Variables needed fo match query results
my $DEAL_ID;		# Deal ID (st.deals.id)
my $SDATE;			# Start Date (st.deals.date_to_show)
my $EDATE;			# End Date (st.deals.date_to_remove)
my $DEAL_URL;			# Direct link for Deal (st.deals.url)
my $SPONSOR;		# Sponsor of Deal (st.deals.display_sponsor)
my $TITLE;			# Deal Title (st.deals.display_title)
my $ENDORSEMENT;	# Does and endorsement page exist? (st.deals.force_endorsement_page)

# MYSQL queries and Updates.
my $DEALS_SEARCH_QUERY = "SELECT display_title, display_sponsor, date_to_show, date_to_remove, url, id, force_endorsement_page FROM deals WHERE date_to_show <  NOW() AND date_to_remove > NOW()";

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

# Just to make sure there are no unexpected newlines
chomp($KEYWORD);
chomp($EMAIL);

# Drop relevant results to a file
open (MAIL_FILE, ">>$MAIL_FILE");

$STH = $DBH->prepare($DEALS_SEARCH_QUERY);
#$STH->execute($KEYWORD) or die "Couldn't execute statement: " . $STH->errstr;
$STH->execute() or die "Couldn't execute statement: " . $STH->errstr;

if ($STH->rows == 0) {
	print "No vaid deals results found...Which is weird.\n";
	exit 0;
} else {
	#print "Found some data\n";
	print MAIL_FILE "Subject: Your Personal Travel Search for: $KEYWORD\n";
	print MAIL_FILE "Initiating Search on key = $KEYWORD\n\n";
	while (@DEALS = $STH->fetchrow_array()) {
		$TITLE = $DEALS[0];
		$SPONSOR = $DEALS[1];
		$SDATE = $DEALS[2];
		$EDATE = $DEALS[3];
		$DEAL_URL = $DEALS[4];
		$DEAL_ID = $DEALS[5];
		$ENDORSEMENT = $DEALS[6];
		#print "$TITLE\n\n";
		if($TITLE =~ /$KEYWORD/i) {
			#print "$TITLE\n\n";
			$DO_MAIL = "1";
			print MAIL_FILE "Deal: $TITLE\n";
			print MAIL_FILE "Brought to you by: $SPONSOR\n";
			print MAIL_FILE "Valid From $SDATE to $EDATE\n";
			if($ENDORSEMENT == '1') {
				$DEAL_TYPE = "deal\/";
			} else {
				$DEAL_TYPE = "rd\/";
			}
			$LINK = "$STM_URL$DEAL_TYPE$DEAL_ID" . "\/$CLICK_TYPE" . "\/0\/0\/0\/";
			print MAIL_FILE "Link to Deal: $LINK\n";
			print MAIL_FILE "\n\n\n";
		}

	}
} 
print "\n";
close(MAIL_FILE);

if($DO_MAIL == "1") {
	open(MAIL,"|/usr/sbin/sendmail -f $FROM_EMAIL $EMAIL");
	open (MAIL_FILE, "$MAIL_FILE");
		while(<MAIL_FILE>) {
			print MAIL "$_"
		}
	close(MAIL);
} else {
	print "Nothing to mail\n";
}
# Clean up after ourselves
unlink($MAIL_FILE);

# Newsletter URLS look like href="http://www.shermanstravel.com/rd/1195152/6/0/0/0/11/6388/0"
# 'http://www.shermanstravel.com/'
# 'rd/' means no endorsement page st.force_endorsement_page=0 use 'deal/' if st.force_endorsement_page=1
#  1195152 is the deal ID	 (st.deals.id)
# '3' Hard code to consider it a site click (6 is a newsletter click)
# '0' 
# '0' 
# '0' 
# 11 - person ID - Not needed
# 6388 mailing campaign ID (st.mailing_campaigns_id) -Not Needed
# 0 link on page (auto Increment)
#
