#!/usr/bin/perl

use DBI;
use strict;

# Script to look for recent entries in st.signup_datastores that have
# NULL data values.
# This script should probably plug into nagios for Monitoring
# See https://trac.shermanstravel.com/ticket/7009
#
#mysql> DESC signup_datastores;
#+-----------+--------------+------+-----+---------+----------------+
#| Field     | Type         | Null | Key | Default | Extra          |
#+-----------+--------------+------+-----+---------+----------------+
#| id        | int(11)      | NO   | PRI | NULL    | auto_increment | 
#| cache_key | varchar(255) | YES  | UNI | NULL    |                | 
#| data      | text         | YES  |     | NULL    |                | 
#| updated   | datetime     | YES  |     | NULL    |                | 
#| processed | tinyint(4)   | YES  |     | 0       |                | 
#+-----------+--------------+------+-----+---------+----------------+

my $COUNT;
my $DB_Database = "st";
#my $DB_Host = "db4";          # 10.131.125.94"
my $DB_Host = "vdb";          # 10.131.125.90"
my $DB_Username = "webuser";
my $DB_Password = "[Redacted]";

my $dbh=DBI->connect("DBI:mysql:host=$DB_Host;database=$DB_Database","$DB_Username", "$DB_Password", {PrintError=>0, RaiseError=>0})
	or
	die("Failed connecting to Db4 ".
	"(error number $DBI::err): $DBI::errstr\n"); 

my $Query = "SELECT COUNT(*) FROM signup_datastores WHERE data IS NULL AND updated BETWEEN DATE_SUB(NOW(), INTERVAL 30 MINUTE) AND NOW()";
my $sth = $dbh->prepare($Query);
$sth->execute();
$COUNT = $sth->fetchrow();

# If $COUNT is not a number, something wierd is going on
unless($COUNT =~ /\d+/) {
	print "UNKNOWN:  An unknown error occured, cannot make sense of teh output.  Count=$COUNT\n";
	exit 3;
}
# If our count is greater then two, we have a problem
if($COUNT == "0") {
	 print "OK: No NULL entries found in st.signup_datastores\n";
	 exit 0;
} elsif($COUNT == "1") {
	print "WARNING: NULL value found in st.signup_datastores Count=$COUNT\n";
	exit 1;
} elsif ($COUNT >= "2") {
	print "CRITICAL: multiple NULL data entries found in st.signup_datastores. Count=$COUNT\n";
	exit 2;
} 

$sth->finish();
$dbh->disconnect();

