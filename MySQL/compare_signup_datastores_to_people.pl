#!/usr/bin/perl

use DBI;
use strict;

# Script to look for recent entries in st.signup_datastores 
# and compare against the people table.  Is every valid processed
# entry getting added to the people table as expected.
# (Or can we verify how well one translates to the other?)
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
#mysql> DESC people;
#+-----------------------+---------------------+------+-----+---------+----------------+
#| Field                 | Type                | Null | Key | Default | Extra          |
#+-----------------------+---------------------+------+-----+---------+----------------+
#| id                    | int(10) unsigned    | NO   | PRI | NULL    | auto_increment | 
#| visitor_id            | int(10) unsigned    | YES  | MUL | NULL    |                | 
#| address_id            | int(10) unsigned    | YES  | MUL | NULL    |                | 
#| first_name            | varchar(125)        | YES  |     | NULL    |                | 
#| last_name             | varchar(65)         | YES  |     | NULL    |                | 
#| email                 | varchar(100)        | NO   | MUL | NULL    |                | 
#| created               | datetime            | YES  | MUL | NULL    |                | 
#| modified              | datetime            | YES  |     | NULL    |                | 
#| refer_id              | int(10) unsigned    | YES  |     | NULL    |                | 
#| source                | varchar(255)        | NO   |     |         |                | 
#| is_administrator      | bit(1)              | YES  |     | NULL    |                | 
#| username              | varchar(20)         | YES  | UNI | NULL    |                | 
#| password              | varchar(40)         | YES  |     | NULL    |                | 
#| recovery_requested_at | datetime            | YES  |     | NULL    |                | 
#| registered_at         | datetime            | YES  |     | NULL    |                | 
#| confirmed_at          | datetime            | YES  |     | NULL    |                | 
#| confirmation_id       | varchar(40)         | YES  | UNI | NULL    |                | 
#| facebook_id           | bigint(20) unsigned | YES  | UNI | NULL    |                | 
#+-----------------------+---------------------+------+-----+---------+----------------+

my $COUNT;
my $DB_Database = "st";
my $DB_Host = "db4";          # 10.131.125.94"
my $DB_Username = "webuser";
my $DB_Password = "[Redacted]";

my $dbh=DBI->connect("DBI:mysql:host=$DB_Host;database=$DB_Database","$DB_Username", "$DB_Password", {PrintError=>0, RaiseError=>0})
	or
	die("Failed connecting to Db4 ".
	"(error number $DBI::err): $DBI::errstr\n"); 

my $DATASTORE_QUERY = "SELECT data FROM signup_datastores WHERE updated BETWEEN '2011-10-13 00:00:00' AND '2011-10-13 23:59:59'";
my $PEOPLE_EMAIL_QUERY = "SELECT COUNT(*) FROM people WHERE email = ?";

my $sth = $dbh->prepare($DATASTORE_QUERY);
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

