#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## On Feb 2, 2012 db1 was purposly separated from db2, breaking the  master master pair.
## (This was done over objections from the system administrator, as it was considered a necessary migration stage)
## 
## old db1 was eventually shut down(Feb 28, 2012) and the data moved to VDB on port 33066.  
## Any time between Feb 6 (launch date)and Feb 28 prod data could have been written to either DB.
## Everything written to db2 stayed and became part of MMW, everything on db1 was stranded
## This script is an attempt to recover some of the data.  
## 
# From Ticket #7942
## We need to move over the old users on the old db1 who are not on the current db1 from the time we had a split brain.
## We simply need the basic user information (email, zip, interests, subscriptions and dates) and do not need their click or open history. We can assign them new user IDs.
## It would be nice to mark them in some way but I'm not sure ho easy that is. Perhaps we could add an extra flag on the refer ID.
##
## Stage #1 Find people records in old db1 from Feb 2012
## Stage #2 Check MMR for all emails, find ones that do not match.
## (Eventually...)
## Stage #3 Add unique records in st.people, st.people_addresses (and then the address_id in people) and st.people_tag_records
## Note: Stage 3 may be handled in another script depending on whether we need to use st.signup_datastores or some aspect of the new user managements system.

my $dbh;                                	# Generic DB Handle
my $sth;
my $HOME = "/home/mking";
my %OPTIONS;
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "vdb";          # 10.131.125.90
$OPTIONS{db_port} = "33066";
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
my $FATAL_ERROR;
my $ERROR_INFO;

my $MIGRATION_FILES_HOME = "/home/mking/marii_bin/db_migration";
my $OLD_DB1_PEOPLE_FILE = "$MIGRATION_FILES_HOME/people_old_db1.txt";
my $LOST_PEOPLE_FILE = "$MIGRATION_FILES_HOME/in_db1_not_mmw.txt";
my $TOTAL_DB1_SUBSCRIBERS = '0';
my $TOTAL_DB_MATCHES = "0";
my $TOTAL_DB_MISSES = "0";
my @PEOPLE_LIST;
my $P_ID;
my $P_ID_2;				# This is a place holder, and should just be a alias of $P_ID
my $P_EMAIL;
my $PA_POSTAL_CODE;
my $R_REFER;
my $P_SOURCE;
my $P_CREATED;
my $P_REFER_ID;
my $P_FIRST_NAME;
my $P_LAST_NAME;
my $PA_ADDRESS;
my $PA_ADDRESS2;
my $PA_CITY;
my $PA_STATE_ID;
my $CURRENT_RECORD;
my $DB_FIELDS_1 = "p.id, p.email, pa.postal_code, r.refer, p.source, p.created, p.refer_id, p.first_name, p.last_name, pa.address, pa.address_2, pa.city, pa.state_id";
#my $SUBSCRIBER;
#my @SUBSCRIBER_LIST;
#my @CURRENT_SUBSCRIBER_LIST;
#my $SUBSCRIPTION_YEAR;

# MYSQL queries and Updates.
# old db1
#my $LEGACY_PEOPLE_QUERY = "SELECT id, email, address_id, created, modified FROM people WHERE created BETWEEN '2012-02-02 00:00:00' AND '2012-02-29 23:59:59'";  
my $LEGACY_PEOPLE_QUERY = "SELECT $DB_FIELDS_1 FROM people AS p
							LEFT JOIN  `people_addresses` AS pa ON p.`address_id` = pa.id 
							LEFT JOIN refers r ON p.refer_id = r.id
							WHERE p.created BETWEEN '2012-02-02 00:00:00' AND '2012-02-29 23:59:59'";
# MMW
my $PEOPLE_DISCOVERY_QUERY = "SELECT id FROM people WHERE email = ?";

#######
## Old db1
## st.people_addresses fields: id, address, address2, city, state_or_territory, postal_code, country_id, phone, fax, city_id, state_id, url
# my $ADDRESS_DISCOVERY_QUERY = "SELECT * FROM people_addresses AS pa, people as p WHERE p.email = ? AND p.addres_id = pa.id";
## st.people_tag_records fields: id, tag_id (link to st.tag.id), association_id (link to st.people.id)
# my $SPECIAL_INTEREST_QUERY = "SELECT * FROM people_tag_records WHERE association_id = ?";
## MMW
#my $ADDRESS_INSERT = "INSERT INTO people ADDRESES VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?)";

## mysql> SELECT * FROM tags WHERE tag_type_id = '1';
##+------+--------------------------+-------------+
##| id   | name                     | tag_type_id |
##+------+--------------------------+-------------+
##| 1241 | All-Inclusive Travel     |           1 | 
##|    8 | Beach                    |           1 | 
##|   13 | Business Travel          |           1 | 
##|    6 | Cruise                   |           1 | 
##| 1271 | Disney                   |           1 | 
##| 1260 | Eco-Travel               |           1 | 
##|    9 | Family                   |           1 | 
##|    4 | Gambling                 |           1 | 
##|   10 | Gay and Lesbian          |           1 | 
##|    7 | Golf                     |           1 | 
##|   12 | International Travel     |           1 | 
##|    1 | Luxury                   |           1 | 
##| 1254 | naturist                 |           1 | 
##|   14 | Romance                  |           1 | 
##|   11 | Senior                   |           1 | 
##|    5 | Skiing                   |           1 | 
##| 1258 | Spas & Resorts           |           1 | 
##|    2 | Sports and Adventure     |           1 | 
##| 1199 | Travel Tips and Strategy |           1 | 
##| 1245 | USAToday                 |           1 | 
##+------+--------------------------+-------------+
##20 rows in set (0.00 sec)
##
##mysql> DESC people_addresses;
##+--------------------+-----------------------+------+-----+---------+----------------+
##| Field              | Type                  | Null | Key | Default | Extra          |
##+--------------------+-----------------------+------+-----+---------+----------------+
##| id                 | int(10) unsigned      | NO   | PRI | NULL    | auto_increment | 
##| address            | varchar(200)          | YES  | MUL | NULL    |                | 
##| address_2          | varchar(160)          | YES  |     | NULL    |                | 
##| city               | varchar(60)           | YES  |     | NULL    |                | 
##| state_or_territory | varchar(25)           | YES  |     | NULL    |                | 
##| postal_code        | varchar(25)           | YES  | MUL | NULL    |                | 
##| country_id         | mediumint(6) unsigned | YES  |     | NULL    |                | 
##| phone              | varchar(75)           | YES  |     | NULL    |                | 
##| fax                | varchar(25)           | YES  |     | NULL    |                | 
##| city_id            | int(11)               | YES  |     | NULL    |                | 
##| state_id           | int(11)               | YES  |     | NULL    |                | 
##| url                | varchar(80)           | YES  |     | NULL    |                | 
##+--------------------+-----------------------+------+-----+---------+----------------+
##12 rows in set (0.03 sec)

print "Grabbing password file\n";
# Open the file with the mysql password
open (FH, "$OPTIONS{db_password_file}");
flock FH,2;
$OPTIONS{mysql_password}=<FH>;
close FH;
chomp $OPTIONS{mysql_password};

print "Initiating database connection.\n";
db_connect();

# Lets create a directory, to the migration files into if it does not already exist
unless(-d "$MIGRATION_FILES_HOME") {
	print "Making $MIGRATION_FILES_HOME for storage of mail files.\n";
	mkdir("$MIGRATION_FILES_HOME",0777) || die "Cannot mkdir $MIGRATION_FILES_HOME: $!";
}
# Lets Open a file to keep track of legacy users
open(OLD_DB1, ">$OLD_DB1_PEOPLE_FILE");
print OLD_DB1 "$DB_FIELDS_1\n";

# O.K.  Lets get a list of active users
print "Grabbing Users registered in February 2012 from old db1\n";
$sth = $dbh->prepare($LEGACY_PEOPLE_QUERY);
$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
while (@PEOPLE_LIST = $sth->fetchrow_array()) {
	$P_ID = $PEOPLE_LIST[0];
	$P_EMAIL = $PEOPLE_LIST[1];
	$PA_POSTAL_CODE = $PEOPLE_LIST[2];
	$R_REFER = $PEOPLE_LIST[3];
	$P_SOURCE = $PEOPLE_LIST[4];
	$P_CREATED = $PEOPLE_LIST[5];
	$P_REFER_ID = $PEOPLE_LIST[6];
	$P_FIRST_NAME = $PEOPLE_LIST[7];
	$P_LAST_NAME = $PEOPLE_LIST[8];
	$PA_ADDRESS = $PEOPLE_LIST[9];
	$PA_ADDRESS2 = $PEOPLE_LIST[10];
	$PA_CITY = $PEOPLE_LIST[11];
	$PA_STATE_ID = $PEOPLE_LIST[12];
	print OLD_DB1 "$P_ID,$P_EMAIL,$PA_POSTAL_CODE,$R_REFER,$P_SOURCE,$P_CREATED,$P_REFER_ID,$P_FIRST_NAME,$P_LAST_NAME,$PA_ADDRESS,$PA_ADDRESS2,$PA_CITY,$PA_STATE_ID\n";
	++$TOTAL_DB1_SUBSCRIBERS;
}

# We should be done with this file
close(OLD_DB1);

# Close out our current DB connections so we can swap to the production DBs
$sth->finish();
$dbh->disconnect();

# Set options for cnnection to MMW
$OPTIONS{db_hostname} = "mmr";          # 10.131.125.192
$OPTIONS{db_port} = "3306";

# Initiate connection to producton dbs
print "Connection to MMR to check records.\n";
db_connect();

# Lets Open some files for keeping Track
open(OLD_DB1, "$OLD_DB1_PEOPLE_FILE");
open(NOT_IN_MMW, ">$LOST_PEOPLE_FILE");

while(<OLD_DB1>) {
	chomp;
	if(/$DB_FIELDS_1/) {
		print "Skipping Header Line.\n";
		next;
	}
	($P_ID,$P_EMAIL,$PA_POSTAL_CODE,$R_REFER,$P_SOURCE,$P_CREATED,$P_REFER_ID,$P_FIRST_NAME,$P_LAST_NAME,$PA_ADDRESS,$PA_ADDRESS2,$PA_CITY,$PA_STATE_ID) = split(/,/);
	$CURRENT_RECORD = "$P_ID,$P_EMAIL,$PA_POSTAL_CODE,$R_REFER,$P_SOURCE,$P_CREATED,$P_REFER_ID,$P_FIRST_NAME,$P_LAST_NAME,$PA_ADDRESS,$PA_ADDRESS2,$PA_CITY,$PA_STATE_ID";
	$sth = $dbh->prepare($PEOPLE_DISCOVERY_QUERY);
	$sth->execute($P_EMAIL) or die "Couldn't execute statement: " . $sth->errstr;
	# If we get a hit, that means they are in both DBS, 
	# so I remove them from further scruitiny
	$P_ID_2 = $sth->fetchrow();
	if($sth->rows == 0) {
		print NOT_IN_MMW "$CURRENT_RECORD\n";
		++$TOTAL_DB_MISSES;
	} else {
		++$TOTAL_DB_MATCHES;
		#print "Putting $SUBSCRIBER in current bucket\n";
	}
}	

print "Total db1 Subscribers From February Found: $TOTAL_DB1_SUBSCRIBERS\n";
print "Number that were matched in new DB: $TOTAL_DB_MATCHES\n";
print "Number of users that need to be added to production: $TOTAL_DB_MISSES\n";

# Finally close out our DB connections
$sth->finish();
$dbh->disconnect();

sub db_connect {
# if our database handle cannot connect, spit out an error string and die
	if (!($dbh = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}:$OPTIONS{db_port}","$OPTIONS{db_username}","$OPTIONS{mysql_password}"))) {
		$FATAL_ERROR=1;
		$ERROR_INFO.= "DB connect error! $DBI::errstr";
		return 1;
	}
}

sub mysql_date {
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
}
