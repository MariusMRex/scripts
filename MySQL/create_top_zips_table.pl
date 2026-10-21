#!/usr/bin/perl

use DBI;
use strict;

# The purpose of this script is to update the st.top_zips table.
# Sandy sent me a new copy of teh data on October 14th, 2011
# st.tops_zips already exists, so we are going to drop it and
# recreate it
#
# Currently the information on top zips is in a CSV file
# in the form of Zip Code,City,State
# /home/mking/zip_code-top-hii-11-03-2010.csv
#

my $DB_Database = "st";
my $DB_Host = "db1";          # 10.131.125.191 MMM Interface (We need to write to DB1, since every DB has this table)
my $DB_Username = "webuser";
my $DB_Password = "[Redacted]";

my $INSERT = "INSERT into top_zips set postal_code = ?";
my $ZIPCODE_FILE = "/home/mking/zip_code-top-hii-11-03-2010.csv";
my $ZIPCODE;
my $CITY;
my $STATE;



# Connect to the Database and a handle to work with
my $dbh=DBI->connect("DBI:mysql:host=$DB_Host;database=$DB_Database","$DB_Username", "$DB_Password", {PrintError=>0, RaiseError=>0})
	or
	die("Failed connecting to Db4 ".
	"(error number $DBI::err): $DBI::errstr\n"); 
my $sth;

# DROP the old table and create a new one
$dbh->do("DROP TABLE IF EXISTS top_zips");
$dbh->do("CREATE TABLE IF NOT EXISTS `top_zips` (
	`postal_code` varchar(25) NOT NULL,
	PRIMARY KEY  (`postal_code`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8");

# Lets open our text file for reading
open(TOP_ZIPS, "$ZIPCODE_FILE");

while(<TOP_ZIPS>) {
	if($_ =~ /^Zip Code,City,State$/) {
		print "skipping header\n";
		next;
	}
	($ZIPCODE,$CITY,$STATE) = split(/,/);
	if($ZIPCODE =~ /\d\d+/) {
		print "Processing $ZIPCODE\n";
		$sth = $dbh->prepare($INSERT);
		$sth->execute($ZIPCODE);
	} 
}

$sth->finish();
$dbh->disconnect();

