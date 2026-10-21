#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## One of the developers added a bunch of records to the database for people
## by accident.  This script is intended to go through and remove the records
## so the people can be re-added properly  
##
## So basically I took a dump of the people records that got added by accident
## Put it into CSV format and will run it through this script.  This script connects
## to stsite-mysqldb02 and removed the records.  All other dbs will pick it up
## from the mysql slave setup.
##
## Marius 2012-04-26

my $dbh;                                	# Generic DB Handle
my $sth;
my $HOME = "/home/marius";
my %OPTIONS;
$OPTIONS{db_name} = "st";
#$OPTIONS{db_hostname} = "db4";          # 10.131.125.94
$OPTIONS{db_hostname} = "mysqldb02.shermanstravel.com";          # stsite DB
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

my $FILE = $ARGV[0];

my $P_ID;
my $P_VISITOR_ID;
my $P_ADDRESS_ID;
my $P_FIRST_NAME;
my $P_LAST_NAME;
my $P_EMAIL;
my $P_CREATED;
my $P_MODIFIED;
my $P_REFER_ID;
my $P_SOURCE;
my $P_IS_ADMIN;
my $P_USERNAME;
my $P_PASS;
my $P_RECOVERY_REQUEST;
my $P_REGISTERED_AT;
my $P_CONFIRMED_AT;
my $P_CONFIRMATION_ID;
my $P_FACEBOOK_ID;

# This is what my data looks like:
# "id","visitor_id","address_id","first_name","last_name","email","created","modified","refer_id","source","is_administrator","username","password","recovery_requested_at","registered_at","confirmed_at","confirmation_id","facebook_id"
#15800157,,9997649,"","","aventajadonestora@yahoo.com","2012-04-26 17:48:28","2012-04-26 17:48:28",29590707,"",,"","","","","","",
#15800158,,9997650,"","","genaleen06@yahoo.com","2012-04-26 17:48:28","2012-04-26 17:48:28",29590707,"",,"","","","","","",
#15800159,,9997651,"","","indaclinderma@yahoo.co.id","2012-04-26 17:48:29","2012-04-26 17:48:29",29590707,"",,"","","","","","",

# MYSQL queries and Updates.
my $DELETE_FROM_ACTIONS = "DELETE FROM actions WHERE person_id = ?";
my $DELETE_FROM_PEOPLE_ADDRESSES = "DELETE FROM people_addresses WHERE id = ?";
my $DELETE_FROM_SUBSCRIPTIONS = "DELETE FROM subscriptions WHERE person_id = ?";
my $DELETE_FROM_PEOPLE = "DELETE FROM people WHERE id = ? AND email = ?";

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

open(PEOPLE, "$FILE");
while(<PEOPLE>) {
	chomp();
	s/\"//g;
	print "$_\n";
	($P_ID, $P_VISITOR_ID, $P_ADDRESS_ID, $P_FIRST_NAME, $P_LAST_NAME, $P_EMAIL, $P_CREATED, $P_MODIFIED, $P_REFER_ID, $P_SOURCE, $P_IS_ADMIN, $P_USERNAME, $P_PASS, $P_RECOVERY_REQUEST, $P_REGISTERED_AT, $P_CONFIRMED_AT, $P_CONFIRMATION_ID, $P_FACEBOOK_ID) = split(/,/);
	print "Removing record from st.actions: DELETE FROM actions WHERE person_id = $P_ID\n";
	$sth = $dbh->prepare($DELETE_FROM_ACTIONS);
        $sth->execute($P_ID) or die "Couldn't execute statement: " . $sth->errstr;

	print "Removing record from st.people_addresses: DELETE FROM people_addresses WHERE id = $P_ADDRESS_ID\n";
	$sth = $dbh->prepare($DELETE_FROM_PEOPLE_ADDRESSES);
        $sth->execute($P_ADDRESS_ID) or die "Couldn't execute statement: " . $sth->errstr;

	print "Removing record from st.subscriptions: DELETE FROM subscriptions WHERE person_id = $P_ID\n";
	$sth = $dbh->prepare($DELETE_FROM_SUBSCRIPTIONS);
	$sth->execute($P_ID) or die "Couldn't execute statement: " . $sth->errstr;

	print "Removing record from st.people: DELETE FROM people WHERE id = $P_ID AND email = $P_EMAIL\n";
	$sth = $dbh->prepare($DELETE_FROM_PEOPLE);
	$sth->execute($P_ID,$P_EMAIL) or die "Couldn't execute statement: " . $sth->errstr;

	print"\n";
	sleep 5;
}

# Finally close out our DB connections
$sth->finish();
$dbh->disconnect();
