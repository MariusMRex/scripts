#!/usr/bin/perl

use DBI;
use strict;

# Sandy gave us a spread sheet of Top 500 US zips.
# We want to compare this list against our luxury
# signups to see how they match up.
# Currently I have a copy of the top zips in
# /home/mking/zip_code-top-hii-11-03-2010.csv
#
#mysql> DESC derived_address;
#+-------------------------------+------------------+------+-----+---------+-------+
#| Field                         | Type             | Null | Key | Default | Extra |
#+-------------------------------+------------------+------+-----+---------+-------+
#| person_id                     | int(10) unsigned | NO   |     | NULL    |       | 
#| email                         | varchar(100)     | NO   |     | NULL    |       | 
#| city                          | varchar(60)      | YES  |     | NULL    |       | 
#| state_or_territory            | varchar(25)      | YES  |     | NULL    |       | 
#| postal_code                   | varchar(25)      | YES  |     | NULL    |       | 
#| derived_dma                   | int(11)          | YES  |     | 0       |       | 
#| subscr_bulletin               | enum('N','Y')    | NO   |     | N       |       | 
#| subscr_top25                  | enum('N','Y')    | NO   |     | N       |       | 
#| subscr_usat                   | enum('N','Y')    | NO   |     | N       |       | 
#| subscr_luxe15                 | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_beach           | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_business_travel | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_cruise          | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_family          | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_gambling        | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_gay             | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_golf            | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_international   | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_luxury          | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_romance         | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_senior          | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_skiing          | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_spa             | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_sport           | enum('N','Y')    | NO   |     | N       |       | 
#| spec_interest_travel_tips     | enum('N','Y')    | NO   |     | N       |       | 
#| active                        | enum('N','Y')    | NO   |     | Y       |       | 
#| created                       | datetime         | YES  |     | NULL    |       | 
#+-------------------------------+------------------+------+-----+---------+-------+
#
# And our data file for zip codes looks like this
# Zip Code,City,State

my $ZIPCODE_FILE = "/home/mking/zip_code-top-hii-11-03-2010.csv";
my $ZIPCODE;
my $CITY;
my $STATE;
my $TOP_ZIPS_COUNT = "0";
my $TOP_ZIPS_TOTAL = "0";
my $LUX_15_COUNT = "0";
my $LUX_15_TOTAL = "0";
my $SPEC_INTEREST_LUXURY_COUNT = "0";
my $SPEC_INTEREST_LUXURY_TOTAL = "0";
my $BOTH_AND_COUNT = "0";
my $BOTH_AND_TOTAL = "0";
my $BOTH_OR_COUNT = "0";
my $BOTH_OR_TOTAL = "0";
my $NO_LUX_COUNT = "0";
my $NO_LUX_TOTAL = "0";
my $LUXURY_NO_TOP_ZIP;
my $DB_Database = "st";
my $DB_Host = "10.131.125.94";          # db4 
my $DB_Username = "webuser";
my $DB_Password = "[Redacted]";

my $sth;
my $dbh=DBI->connect("DBI:mysql:host=$DB_Host;database=$DB_Database","$DB_Username", "$DB_Password", {PrintError=>0, RaiseError=>0})
	or
	die("Failed connecting to Db4 ".
	"(error number $DBI::err): $DBI::errstr\n"); 

#my $COUNT_QUERY = "SELECT COUNT(*) FROM derived_address WHERE postal_code = ?";
#my $LUX_QUERY = "SELECT COUNT(*) FROM derived_address WHERE postal_code = ? AND subscr_luxe15 = 'Y'";
#my $SPEC_INTEREST_QUERY = "SELECT COUNT(*) FROM derived_address WHERE postal_code = ? AND spec_interest_luxury = 'Y'";
#my $ALL_LUX_AND_QUERY = "SELECT COUNT(*) FROM derived_address WHERE postal_code = ? AND spec_interest_luxury = 'Y' AND subscr_luxe15 = 'Y'";
#my $ALL_LUX_OR_QUERY = "SELECT COUNT(*) FROM derived_address WHERE postal_code = ? AND (spec_interest_luxury = 'Y' OR subscr_luxe15 = 'Y')";
#my $NO_LUXURY_QUERY = "SELECT COUNT(*) FROM derived_address WHERE postal_code = ? AND spec_interest_luxury = 'N' AND subscr_luxe15 = 'N'";

# Lets do this ruling out the inactive users identified by long_time_no_clicky.
# Table in db4 thanks to create_inactive_subscriber_table.pl
my $COUNT_QUERY = "SELECT COUNT(*) FROM derived_address WHERE postal_code = ? AND (person_id NOT IN(SELECT person_id FROM inactive_10_19_2011_tmp))";
my $LUX_QUERY = "SELECT COUNT(*) FROM derived_address WHERE postal_code = ? AND subscr_luxe15 = 'Y' AND (person_id NOT IN(SELECT person_id FROM inactive_10_19_2011_tmp))";
my $SPEC_INTEREST_QUERY = "SELECT COUNT(*) FROM derived_address WHERE postal_code = ? AND spec_interest_luxury = 'Y' AND (person_id NOT IN(SELECT person_id FROM inactive_10_19_2011_tmp))";
my $ALL_LUX_AND_QUERY = "SELECT COUNT(*) FROM derived_address WHERE postal_code = ? AND spec_interest_luxury = 'Y' AND subscr_luxe15 = 'Y' AND (person_id NOT IN(SELECT person_id FROM inactive_10_19_2011_tmp))";
my $ALL_LUX_OR_QUERY = "SELECT COUNT(*) FROM derived_address WHERE postal_code = ? AND (spec_interest_luxury = 'Y' OR subscr_luxe15 = 'Y') AND (person_id NOT IN(SELECT person_id FROM inactive_10_19_2011_tmp))";
my $NO_LUXURY_QUERY = "SELECT COUNT(*) FROM derived_address WHERE postal_code = ? AND spec_interest_luxury = 'N' AND subscr_luxe15 = 'N' AND (person_id NOT IN(SELECT person_id FROM inactive_10_19_2011_tmp))";
my $NO_TOP_ZIP_QUERY = "SELECT COUNT(*) FROM derived_address WHERE (postal_code NOT IN (SELECT postal_code FROM top_zips)) AND (spec_interest_luxury = 'Y' OR subscr_luxe15 = 'Y') AND (person_id NOT IN(SELECT person_id FROM inactive_10_19_2011_tmp))";

open(ZIPCODES, "$ZIPCODE_FILE");
while(<ZIPCODES>) {
	if($_ =~ /^Zip Code,City,State$/) {
		print "skipping header\n";
		next;
	}
	($ZIPCODE,$CITY,$STATE) = split(/,/);
	print "$ZIPCODE\n";

	$sth = $dbh->prepare($COUNT_QUERY);
	$sth->execute($ZIPCODE);
	$TOP_ZIPS_COUNT = $sth->fetchrow();
	$TOP_ZIPS_TOTAL = $TOP_ZIPS_TOTAL + $TOP_ZIPS_COUNT;

	$sth = $dbh->prepare($LUX_QUERY);
	$sth->execute($ZIPCODE);
	$LUX_15_COUNT = $sth->fetchrow();
	$LUX_15_TOTAL = $LUX_15_COUNT + $LUX_15_TOTAL;

	$sth = $dbh->prepare($SPEC_INTEREST_QUERY);
	$sth->execute($ZIPCODE);
	$SPEC_INTEREST_LUXURY_COUNT = $sth->fetchrow();
	$SPEC_INTEREST_LUXURY_TOTAL = $SPEC_INTEREST_LUXURY_TOTAL + $SPEC_INTEREST_LUXURY_COUNT;

	$sth = $dbh->prepare($ALL_LUX_AND_QUERY);
	$sth->execute($ZIPCODE);
	$BOTH_AND_COUNT= $sth->fetchrow();
	$BOTH_AND_TOTAL = $BOTH_AND_TOTAL + $BOTH_AND_COUNT;

	$sth = $dbh->prepare($ALL_LUX_OR_QUERY);
	$sth->execute($ZIPCODE);
	$BOTH_OR_COUNT= $sth->fetchrow();
	$BOTH_OR_TOTAL = $BOTH_OR_TOTAL + $BOTH_OR_COUNT;

	$sth = $dbh->prepare($NO_LUXURY_QUERY);
	$sth->execute($ZIPCODE);
	$NO_LUX_COUNT= $sth->fetchrow();
	$NO_LUX_TOTAL = $NO_LUX_TOTAL + $NO_LUX_COUNT;
}

# Now lets do the query for luxury subscribers who are not in top zips
$sth = $dbh->prepare($NO_TOP_ZIP_QUERY);
$sth->execute();
$LUXURY_NO_TOP_ZIP = $sth->fetchrow();

# Now close the database connection
$sth->finish();
$dbh->disconnect();

# And report
print "How many folks in the top zip codes specify and interest in Luxury?\n";
print "=====================================================\n";
print "Subscribers who live in top zip codes: $TOP_ZIPS_TOTAL\n";
print "Subscribers who live in top zips codes and also subscribe to Smart Luxury: $LUX_15_TOTAL\n";
print "Subscribers who live in top zips codes and specify a special interest in luxury: $SPEC_INTEREST_LUXURY_TOTAL\n";
print "Subscribers who live in top zips codes and are both Smart Luxury subscribers and specify a special interest in Luxury: $BOTH_AND_TOTAL\n";
print "Subscribers who live in top zips codes and are either a Smart Luxury subscriber or specify a special interest in Luxury: $BOTH_OR_TOTAL\n";
print "Subscribers who live in top zip codes but are neither a Smart Luxury subscriber nor specify a special interests in Luxury: $NO_LUX_TOTAL\n";
print "Subscribers who indicate luxury in their profiles but do not live in a top zipcode: $LUXURY_NO_TOP_ZIP\n";
