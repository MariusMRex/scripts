#!/usr/bin/perl

use DBI;
use strict;

# The purpose of this script is to read in the file I created
# with the script long_time_no_clicky.pl and to create
# A temporary database table so I can query against it.
#
# Currently the information is in a flat file which is just
# a list of person_ids.
# /home/mking/never_been_clicked.txt
#
# After I read that in, I can modify other scripts to run
# Against it.

my $DB_Database = "st";
my $DB_Host = "db4";          # 10.131.125.94"
my $DB_Username = "webuser";
my $DB_Password = "[Redacted]";

my $INSERT = "INSERT into inactive_10_19_2011_tmp VALUES(NULL, ?)";
my $DATAFILE = "/home/mking/never_been_clicked.txt";
my $USER_ID;


# Connect to the Database and a handle to work with
my $dbh=DBI->connect("DBI:mysql:host=$DB_Host;database=$DB_Database","$DB_Username", "$DB_Password", {PrintError=>0, RaiseError=>0})
	or
	die("Failed connecting to Db4 ".
	"(error number $DBI::err): $DBI::errstr\n"); 
my $sth;

# Create our temp table
$dbh->do("CREATE TABLE IF NOT EXISTS `inactive_10_19_2011_tmp` (
	`id` INT(10) unsigned NOT NULL auto_increment,
	`person_id` int(10) unsigned NOT NULL default '0',
	PRIMARY KEY  (`id`),
	UNIQUE KEY `person_id` (`person_id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8");

# Lets open our text file for reading
open(INACTIVE_USERS, "$DATAFILE");

while(<INACTIVE_USERS>) {
	chomp;
	$USER_ID = $_;
	if($USER_ID =~ /\d\d+/) {
		$sth = $dbh->prepare($INSERT);
		$sth->execute($USER_ID);
	} 
}

$sth->finish();
$dbh->disconnect();

