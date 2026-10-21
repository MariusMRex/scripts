#!/usr/bin/perl

use DBI;
use strict;

# Script to mimic Weekly Email Frequency Report to
# Double check the numbers, just in case.
# 
# Lets run this against db2, since this is a long running
# script and that DB is pretty much idle
#
#mysql> DESC derived_address_history;
#+-------------+------------------+------+-----+---------+----------------+
#| Field       | Type             | Null | Key | Default | Extra          |
#+-------------+------------------+------+-----+---------+----------------+
#| id          | int(10) unsigned | NO   | PRI | NULL    | auto_increment | 
#| person_id   | int(10) unsigned | NO   | MUL | NULL    |                | 
#| send_date   | datetime         | YES  |     | NULL    |                | 
#| campaign_id | int(10) unsigned | NO   | MUL | NULL    |                | 
#+-------------+------------------+------+-----+---------+----------------+

my $COUNT;
my $DB_Database = "st";
my $DB_Host = "10.131.125.91";          # db1
my $DB_Username = "webuser";
my $DB_Password = "[Redacted]";
my @PEOPLE_HISTORY_COUNT;

my $DAH_PEOPLE;
my $DAH_PEOPLE_COUNT;
my $ONE_COUNT = "0";
my $TWO_COUNT = "0";
my $THREE_COUNT = "0";
my $FOUR_COUNT = "0";
my $FIVE_COUNT = "0";
my $SIX_COUNT = "0";
my $SEVEN_COUNT = "0";

# Lets get some date ifnormation set
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

my $dbh=DBI->connect("DBI:mysql:host=$DB_Host;database=$DB_Database","$DB_Username", "$DB_Password", {PrintError=>0, RaiseError=>0})
	or
	die("Failed connecting to Db4 ".
	"(error number $DBI::err): $DBI::errstr\n"); 

#my $Query = "SELECT person_id, COUNT(person_id) FROM derived_address_history WHERE send_date BETWEEN '2011-10-05 06:00:00' AND '2011-10-12 06:00:00' GROUP BY person_id";
#my $Query = "SELECT person_id, COUNT(person_id) FROM derived_address_history WHERE send_date BETWEEN DATE_SUB('2012-06-06 06:00:00', INTERVAL 7 DAY) AND '2012-06-06 06:00:00' GROUP BY person_id";
my $Query = "SELECT person_id, COUNT(person_id) FROM derived_address_history WHERE send_date BETWEEN DATE_SUB(CURDATE(), INTERVAL 7 DAY) AND CURDATE() GROUP BY person_id";
my $sth = $dbh->prepare($Query);
$sth->execute();
while (@PEOPLE_HISTORY_COUNT = $sth->fetchrow_array()) {
	$DAH_PEOPLE = $PEOPLE_HISTORY_COUNT[0];
	$DAH_PEOPLE_COUNT = $PEOPLE_HISTORY_COUNT[1];
	#print "|$DAH_PEOPLE|$DAH_PEOPLE_COUNT|\n";
	if($DAH_PEOPLE_COUNT == '1') {
		++$ONE_COUNT;
	}
	if($DAH_PEOPLE_COUNT == '2') {
		++$TWO_COUNT;
	}
	if($DAH_PEOPLE_COUNT == '3') {
		++$THREE_COUNT;
	}
	if($DAH_PEOPLE_COUNT == '4') {
		++$FOUR_COUNT;
	}
	if($DAH_PEOPLE_COUNT == '5') {
		++$FIVE_COUNT;
	}
	if($DAH_PEOPLE_COUNT == '6') {
		++$SIX_COUNT;
	}
	if($DAH_PEOPLE_COUNT == '7') {
		++$SEVEN_COUNT;
	}

}
$sth->finish();
$dbh->disconnect();

print "Email Frequency Stats for 7 Days Prior to $DATE\n";
print "=====================================================\n";
print "Number of people receiving (01) email over the past 7 days: $ONE_COUNT\n";
if($TWO_COUNT > '0'){
	print "Number of people receiving (02) email over the past 7 days: $TWO_COUNT\n";
}
if($THREE_COUNT > '0'){
	print "Number of people receiving (03) email over the past 7 days: $THREE_COUNT\n";
}
if($FOUR_COUNT > '0'){
	print "Number of people receiving (04) email over the past 7 days: $FOUR_COUNT\n";
}
if($FIVE_COUNT > '0'){
	print "Number of people receiving (05) email over the past 7 days: $FIVE_COUNT\n";
}
if($SIX_COUNT > '0'){
	print "Number of people receiving (06) email over the past 7 days: $SIX_COUNT\n";
}
if($SEVEN_COUNT > '0'){
	print "Number of people receiving (07) email over the past 7 days: $SEVEN_COUNT\n";
}

