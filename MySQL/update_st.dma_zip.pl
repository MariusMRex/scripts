#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## Kal paid a large amount of money to get an updated zip to DMA mapping.
## We do not know how old our list is, or how badly it needs to be updated.
## But as long as we paid for it, we will certainly use it. 
##
## So I have a CSV file called DMABYZIP1112.csv with the following fields:
## "ZIP CODE","DMA NAME","DMA CODE","ADDITIONAL DMA","STATE CODE","CTY CODE","ST ABREV","CTY NAME","CTY SIZE","NMR TERR","NOT USED","DMA RANK","METRO INDIC"
##
## st.dma_zip has these fields
##mysql> DESC dma_zip;
##+-------------+----------------------+------+-----+---------+-------+
##| Field       | Type                 | Null | Key | Default | Extra |
##+-------------+----------------------+------+-----+---------+-------+
##| zip_code    | char(5)              | NO   | PRI | NULL    |       | 
##| state       | char(2)              | YES  |     | NULL    |       | 
##| state_code  | tinyint(2) unsigned  | YES  |     | NULL    |       | 
##| county_code | smallint(4) unsigned | YES  |     | NULL    |       | 
##| dma         | smallint(4) unsigned | YES  |     | NULL    |       | 
##+-------------+----------------------+------+-----+---------+-------+
## 
## So I can map:
## zip_code = field 1 of CSV
## state = field 7
## state_code field 5
## county_code = field 6
## dma = field 2
##
## Step #1 Before DMA Count
## SELECT derived_dma AS DMA, COUNT(DISTINCT person_id) AS COUNT FROM derived_address GROUP BY derived_dma;
##
## Step #2 Detect changes.
## Walk though and check each zip to dma mapping and see if it matches?
##
## Marius 2012-05-04
##
## Results from phase #2
## Match: 318
## Miss: 50309
## New: 205
## 
## Phase #3 - drop st.dma_zip and replace the data with the new mappings from the CSV file.

my $dbh;                                	# Generic DB Handle
my $sth;
#my $HOME = "/home/mking";
my $HOME = "/home/marius";
my %OPTIONS;
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "db1";          # 10.131.125.91
#$OPTIONS{db_hostname} = "stsite-db";          # For wring to the master stsite DB
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
my $FATAL_ERROR;
my $ERROR_INFO;

# Needed for dma count
my @SUBSCRIBER_DATA;
my $DMA;
my $DMA_COUNT;
# Needed to unwrap CSV file
my $SOURCE_FILE = "$HOME/Desktop/CSV/2011-2012_Zip_by_DMA/DMABYZIP1112.csv";
my $HEADER = "ZIP,DMA,DMA,ADDITIONAL,ST.,CTY,ST,CTY,CTY,NMR,NOT,DMA,METRO";
my $HEADER2 = "CODE,CODE,NAME,DMA,CODE,CODE,ABV,NAME,SIZE,TERR.,USED,RANK,INDIC.";
my $ZIP_CODE;
my $DMA_NAME;
my $DMA_CODE;
my $ADDITIONAL_DMA;
my $STATE_CODE;
my $CTY_CODE;
my $ST_ABREV;
my $CTY_NAME; 
my $CTY_SIZE;
my $NMR_TERR;
my $NOT_USED;
my $DMA_RANK;
my $METRO_INDIC;
# Needed for CVS to database comparison.
my $DB_DMA;
my $RECORD_MATCH_COUNT = '0';
my $RECORD_MISS_COUNT = '0';
my $NEW_ROW_COUNT = '0';

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

# MYSQL queries and Updates.
#my $SUBSCRIBER_QUERY = "SELECT person_id FROM derived_address ORDER BY RAND() LIMIT 500";
#my $DMA_COUNT_QUERY = 'SELECT derived_dma, COUNT(DISTINCT person_id) FROM derived_address GROUP BY derived_dma';
my $VERIFY_DMA_QUERY = 'SELECT dma FROM dma_zip WHERE zip_code = ?';
my $POPULATE_DMA_ZIP_INSERT = 'INSERT INTO dma_zip VALUES (?, ?, ?, ?, ?)';

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

# Get current DMA count and print that out (stage #1)
#print "$DATE\n";
#print "DMA: COUNT\n";
#$sth = $dbh->prepare($DMA_COUNT_QUERY);
#$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
#while (@SUBSCRIBER_DATA = $sth->fetchrow_array()) {
#		$DMA = $SUBSCRIBER_DATA[0];
#		$DMA_COUNT = $SUBSCRIBER_DATA[1];
#		print "$DMA: $DMA_COUNT\n";
#}
#print "\n\n";

# Lets make the user confirm the run of stage #3
print "This script will completely wipe out the st.dma_zip table found on $OPTIONS{db_hostname}\n";
print "Are you sure you want to do this (y/n)?\n";
my $ANSWER = <STDIN>;
if($ANSWER eq 'y') {
	print "Well O.K., if you are sure.\n\n";
} else {
	print "Cowardly refusing to run as I do not recognize the answer: $ANSWER\n";
	exit 0;
}

# Drop the st.dma_zip table (stage #3 action)
$dbh->do(DROP TABLE 'dma_zip');

# Create a new table in its place: (stage #3 action)
$dbh->do("CREATE TABLE IF NOT EXISTS `dma_zip` (
  `zip_code` char(5) NOT NULL,
  `state` char(2) default NULL,
  `state_code` tinyint(2) unsigned default NULL,
  `county_code` smallint(4) unsigned default NULL,
  `dma` smallint(4) unsigned default NULL,
  PRIMARY KEY  (`zip_code`)
     ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
);


# Open our CSV file 
open(SOURCE_FILE, "$SOURCE_FILE");
while(<SOURCE_FILE>) {
	chomp();
	if(/$HEADER|$HEADER2/) {
		print "Skipping Line: $_\n";
		next;
	}
	($ZIP_CODE, $DMA_NAME, $DMA_CODE, $ADDITIONAL_DMA, $STATE_CODE, $CTY_CODE, $ST_ABREV, $CTY_NAME, $CTY_SIZE, $NMR_TERR, $NOT_USED, $DMA_RANK, $METRO_INDIC) = split(/,/);
#	# We only really care about $ZIP_CODE, $ST_ABREV, $STATE_CODE, $CTY_CODE and $DMA_NAME to map to st.dma_zip 
#	#
#	# Sanity check (stage #2)
#	#print "Record: $ZIP_CODE =  $DMA_NAME\n";
#	$sth = $dbh->prepare($VERIFY_DMA_QUERY);
#	$sth->execute($ZIP_CODE) or die "Couldn't execute statement: " . $sth->errstr;
#	$DB_DMA = $sth->fetchrow();
#	if($sth->rows == 0) {
#		++$NEW_ROW_COUNT;
#	} else {
#		if($DMA eq $DB_DMA) {
#			++$RECORD_MATCH_COUNT;
#		} else {
#			++$RECORD_MISS_COUNT;
#		}
#	}
#}
#print "Match: $RECORD_MATCH_COUNT\n";
#print "Miss: $RECORD_MISS_COUNT\n";
#print "New: $NEW_ROW_COUNT\n";

	# Stage #3 Populate the newly created st.Dma_zip table.
	$sth = $dbh->prepare($POPULATE_DMA_ZIP_INSERT);
	$sth->execute($ZIP_CODE,$ST_ABREV,$STATE_CODE,$CTY_CODE,$DMA_NAME) or die "Couldn't execute statement: " . $sth->errstr;
}

# Finally close out our DB connections
$sth->finish();
$dbh->disconnect();
