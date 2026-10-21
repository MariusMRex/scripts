#!/usr/bin/perl

use strict;
use warnings;

require DBD::mysql;

# This script is to import FTP leads from DealBase, and is meant to server Trac #7724
# Marius 2012-02-14
# Variables to modify when this script is re-puposed for a new ingestion stream:
# $HOME, $INPUT_FILE, $FILE_HEADER, $SUBJECT, $SOURCE
# Possibly $SD_DATA{email_type}m $FIRST_NAME,$LAST_NAME
# and of course the regex for matching the input file

my $CURL_COMMAND = "/usr/bin/curl";		# Date command binary
my $DATE_COMMAND = "/bin/date";		# Date command binary
my $FILE_DATE = `$DATE_COMMAND +%Y%m%d`;	# Datestamp pre-appended to FTP files
	chomp($FILE_DATE);
my $HOME = "/home/dbase";
my $INPUT_FILE = $ARGV[0];
#my $INPUT_FILE = "$HOME/$FILE_DATE.dealbase.csv";
my $REFERER = "D25-DealBase";
my $REFERER_ID = "29714030"; 						
#my $FILE_HEADER = "First,Last,Email ,Zip,IP,Timestamp,Source";	# First Line of every CSV file 
my $FILE_HEADER = "Email,Zip Code";	# First Line of every CSV file 
my $dbh;                                # Generic DB Handle
my $sth;								# generic Statement Handler
my $INSERT_COUNT = 0;					# Reset Counter for new subscribers imported
my $INVALID_COUNT = "0";				# Reset Counter for invalid records found
my $DUPLICATE_COUNT = "0";				# Need to check if the email is already subscribed
my %OPTIONS;							# Database options Hash
$OPTIONS{db_name} = "st";				# We are using the st database
$OPTIONS{db_hostname} = "mmw";          # 10.131.125.191
$OPTIONS{db_username} = "webuser";		# Access using the websuer
#$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
$OPTIONS{mysql_password} = '[Redacted]';		# Normally I would put the password in a file, but I want the lscript user to run this script but not to let the company lifescript access to our password
my $FATAL_ERROR;						# A place to keep Fatal MySQL Errors, if we need it.
my $ERROR_INFO;							# Info on falata errors stored here
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
#my $DATE = "2011-06-26 07:7:01";

# Mail SETTINGS
my $TO = 'mrex@shermanstravelmedia.com';
my $FROM = 'noreply@shermanstravelmedia.com';
my $SUBJECT = 'Daily output from ingest_people_dealbase.pl';


# Variables which should come from input file
my $FIRST_NAME; 				# st.people first_name
my $LAST_NAME;					# st.people last_name
my $EMAIL;					# st.people email
my $EMAIL2;					# Check if duplicate record exists in the database
my $ZIP;					# st.people_addresses postal_code
#my $IP;					# Planning to drop this
#my $TIMESTAMP;					# Planning to drop this
my $SOURCE = "http://www.dealbase.com/";	# Who gave us the lead?
#my $REFERER;					# $SOURCE as referer from st.referer
my $NULL;						# Empty padding for NULL Values

# st.signup_datastores
my $SD_ID;						# Should be Auto Increment
my $SD_CACHE_KEY;				# Without this, the script that processes the st.signup_datastores table will ignore the entry.  Must be uniqe for each record
my %SD_DATA;
$SD_DATA{first_array} = "a:18:{";	# I will have 12 elements
#$SD_DATA{email};				# s:5:"email";s:?:"$EMAIL";'
#$SD_DATA{postal_code}; 			# s:11:"postal_code";s:?:"$ZIP";
#$SD_DATA{refer} = 's:5:"refer";s:18:"D25-LifeScript-t25";';
#$SD_DATA{source_url} = 's:10:"source_url";s:68:"http://lsa.lifescript.com/advantage/hp8831/main.aspx?utm_campaign=hp";';
$SD_DATA{source_url} = 's:10:"source_url";s:24:"http://www.dealbase.com/";';
$SD_DATA{subscription_source_id} = 's:22:"subscription_source_id";i:7;'; 	# Subscription_source_id 7 is 'external; ingestion'
#$SD_DATA{subscription_date} = "s:17:\"subscription_date\";s:?:\"$DATE\";";
$SD_DATA{visitor_id} = 's:10:"visitor_id";N;';
#$SD_DATA{firstname}; 			# 's:9:"firstname";s:?:"$FIRST_NAME";'
#$SD_DATA{lastname}; 			# 's:8:"lastname";s:?:"$LAST_NAME";'
$SD_DATA{address1} = 's:8:"address1";N;';
$SD_DATA{address2} = 's:8:"address2";N;';
$SD_DATA{city} = 's:4:"city";N;';
$SD_DATA{state_id} = 's:8:"state_id";N;';
$SD_DATA{country_id} = 's:10:"country_id";N;';
$SD_DATA{magazine_option} = 's:15:"magazine_option";i:0;';
$SD_DATA{magazine_sourcekey} = 's:18:"magazine_sourcekey";N;';
#$SD_DATA{magazine_sourcekey} = 's:18:"magazine_sourcekey";s:6:"O1A019";';
# Kal does not want us to send the Welcome email (Trac# 7724)
#$SD_DATA{email_type} = 's:10:"email_type";s:17:"top25WelcomeEmail";';
$SD_DATA{email_type} = 's:10:"email_type";s:4:"NULL";';
$SD_DATA{end_array} = "}";
my $SD_UPDATED = "$DATE";
my $SD_PROCESSED = "0";
my $SD_DATA_COMPLETE;			# This will be the full st.signup_datastores data field, once we have all the variables populated
# We are going to need to know some string lengths later
my $LEN_EMAIL;
my $LEN_POSTAL_CODE;
my $LEN_FIRST_NAME;
my $LEN_LAST_NAME;
my $LEN_DATE;
my $LEN_REFERER;
my $LEN_REFERER_ID;

my $INPUT_LINE;
my @REFERER_DATA;

# MYSQL queries and Updates.
my $REFERER_SEARCH_QUERY = "SELECT id FROM refers WHERE refer = ? ";
my $NEW_REFERRER = "INSERT INTO refers VALUES(NULL,'$REFERER',NULL,NULL,NULL,NULL,NULL,NOW(),NOW())";
my $DUPLICATE_CHECK_QUERY = "SELECT p.email FROM people AS p, subscriptions AS s WHERE p.id = s.person_id AND s.subscription_type_id = '2' AND s.is_unsubscribed != '1' AND p.email = ?";
my $NEW_RECORD_INSERT; 			# "INSERT INTO signup_datastores VALUES(NULL,'$SD_CACHE_KEY','SD_DATA_COMPLETE','$SD_UPDATED','$SD_PROCESSED')";

# Sample Pontiflex Data
# $FIRST_NAME,$LAST_NAME,$EMAIL,$ZIP,$IP,$TIMESTAMP,$SOURCE,,,,
# Joana,Balboa,jjoscrew@yahoo.com,90713,166.205.142.25,2.01108E+13,MOB-DanielCota,,,,,
#  Format changed multiple times while the campaign was live.  Here is the current version
# $FIRST_NAME,$LAST_NAME,$EMAIL,$ZIP,$SOURCE

## Open a Mail handle and start some Content
open(MAIL, "|/usr/sbin/sendmail -t");
# Mail Header
print MAIL "To: $TO\n";
print MAIL "From: $FROM\n";
print MAIL "Subject: $SUBJECT\n\n";
# Body of mail worked out in main script

# Lets catch errors while we are at it.
open(STDERR, '>&MAIL');

# Read in the FTP file
open(INPUT_FILE, "$INPUT_FILE");
print MAIL "Reading in $INPUT_FILE\n";

while(<INPUT_FILE>) {
	chomp;
	if(/$FILE_HEADER/) {
		print MAIL "Skipping Header Line: $FILE_HEADER\n";
		next;
	}
# Lets remove some unfortunate characters.
	s/[\'|\"|\%|\?+|\s]//g;
	# Lets do some input validation
    # New rules for post code 4 or more alpha-numeric characters or a dash - Marius 2011-12-28
	if(/[\w.%+-]+@[\w.-]+\.[\w]{2,4},[\w\-]{2,}/) {
		# Parse data by splitting on commas
		($EMAIL,$ZIP) = split(/,/);
		print "Lets just call me Nemo.  My Email is $EMAIL.  My Zip is $ZIP. My Source is $SOURCE\n";
	} else {
		print MAIL "Line did not match: $_\n";
	}
 	# Do not process record unless it has a valid email and zipcode
	unless($EMAIL) {
		print MAIL "Incomplete Record, no email.\n";
		++$INVALID_COUNT;
		next;
	}
	unless($ZIP) {
		print MAIL "Incomplete Record, no zip.\n";
		++$INVALID_COUNT;
		next;
	}
	#unless($SOURCE) {
	#	print MAIL "Incomplete Record, no source.\n";
	#	next;
	#}
# Dealbase truncates zipcodes that start with a '0'
	while(length($ZIP) < '4') {
		#print "Padding four character zipcode ($ZIP) with a '0' ";
		$ZIP = "0" . "$ZIP";
		#print "--newzip: $ZIP\n";
	}
# Need to do so pre-processing on the referer varaible
	#chomp($SOURCE);
# Strip out MOB Header, if it exists
	#if($SOURCE =~ /^(MOB|mob)-(\w*$)/) {
	#	$SOURCE = $2;
	#}
	#$REFERER = "$REFERER_PREFIX" . "$SOURCE";
	#print "Found $REFERER, attempting to verify in database...\n";

	# if our database handle cannot connect, spit out an error string and die
	if (!($dbh = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}","$OPTIONS{db_username}","$OPTIONS{mysql_password}"))) {
	    $FATAL_ERROR=1;
		    $ERROR_INFO.= "DB connect error! $DBI::errstr";
			    return 1;
	}
# Need to check that this email is not already subscribed
#	$sth = $dbh->prepare($DUPLICATE_CHECK_QUERY);
#	$sth->execute($EMAIL) or die "Couldn't execute statement: " . $sth->errstr;
#	$EMAIL2 = $sth->fetchrow();
#	unless($sth->rows == 0) {
#		print MAIL "$EMAIL is already subscribed, skipping";
#		++$DUPLICATE_COUNT;
#		next;
#	}
# We wan a valid $REFERER_ID, so lets see if we can find one.
	#verify_referer($REFERER);
	#print "Using referer_id = $REFERER_ID and moving on\n";

	# Populate the fields of st.signup_datastores that we could not populate before
	$LEN_EMAIL = length($EMAIL);	
	$LEN_POSTAL_CODE = length($ZIP);
	$LEN_DATE = length($DATE);
	#$LEN_FIRST_NAME = length($FIRST_NAME);
	#$LEN_LAST_NAME = length($LAST_NAME);
	$LEN_REFERER = length($REFERER);
	$LEN_REFERER_ID = length($REFERER_ID);
	$SD_DATA{email} = "s:5:\"email\";s:$LEN_EMAIL:\"$EMAIL\";";
	$SD_DATA{postal_code} = "s:11:\"postal_code\";s:$LEN_POSTAL_CODE:\"$ZIP\";";
	$SD_DATA{referer} = "s:5:\"refer\";s:$LEN_REFERER:\"$REFERER\";";
	$SD_DATA{subscription_date} = "s:17:\"subscription_date\";s:$LEN_DATE:\"$DATE\";";
	$SD_DATA{refer_id} = "s:8:\"refer_id\";s:$LEN_REFERER_ID:\"$REFERER_ID\";";
	#$SD_DATA{firstname} = "s:9:\"firstname\";s:$LEN_FIRST_NAME:\"$FIRST_NAME\";";
	#$SD_DATA{lastname} = "s:8:\"lastname\";s:$LEN_LAST_NAME:\"$LAST_NAME\";";
	$SD_DATA{firstname} = "s:9:\"firstname\";N;";
	$SD_DATA{lastname} = "s:8:\"lastname\";N;";
	$SD_CACHE_KEY = randomString(25);
	$SD_DATA_COMPLETE = "$SD_DATA{first_array}$SD_DATA{email}$SD_DATA{postal_code}$SD_DATA{referer}$SD_DATA{source_url}$SD_DATA{subscription_source_id}$SD_DATA{subscription_date}$SD_DATA{visitor_id}$SD_DATA{refer_id}$SD_DATA{firstname}$SD_DATA{lastname}$SD_DATA{address1}$SD_DATA{address2}$SD_DATA{city}$SD_DATA{state_id}$SD_DATA{country_id}$SD_DATA{magazine_option}$SD_DATA{magazine_sourcekey}$SD_DATA{email_type}$SD_DATA{end_array}";
	$NEW_RECORD_INSERT = "INSERT INTO signup_datastores VALUES(NULL,'$SD_CACHE_KEY','$SD_DATA_COMPLETE','$SD_UPDATED','$SD_PROCESSED')";
	#print MAIL "Inserting new Record: VALUES(NULL,'$SD_CACHE_KEY','$SD_DATA_COMPLETE','$SD_UPDATED','$SD_PROCESSED'\n";
	#print MAIL "Inserting new Record: $SD_DATA{email}\n";

	$sth = $dbh->prepare($NEW_RECORD_INSERT);
	$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
	++$INSERT_COUNT;
	# backend only processes 500 log lines every 5 minutes, so lets throttle ingestion
	sleep 4;
}

print MAIL "Record Insert count  = $INSERT_COUNT\n";
print MAIL "Invalid Record Count = $INVALID_COUNT\n";
#print MAIL "Duplicate email Count = $DUPLICATE_COUNT\n";

# Mail out results
close(STDERR);
close(MAIL);

sub randomString {
	# Code adapted from http://paulbradley.tv/30/
	# Paul Brady 01.Jan.2002 
	my $STRING;
	my $_RAND;

	my $STRING_LENGTH = $_[0];
	if (!$STRING_LENGTH) {
		$STRING_LENGTH = 10;
	}
	my @CHARS = split(" ", "a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9");
	
	srand;

	for (my $I=0; $I <= $STRING_LENGTH ;$I++) {
		$_RAND = int(rand 36);
		$STRING .= $CHARS[$_RAND];
	}
	return $STRING;
}

sub verify_referer {
# Does the referrer already exist in st.refers?
	$REFERER = "$_[0]";
	#print "Preparing to look for $REFERER in st.refers table\n"; 
	$sth = $dbh->prepare($REFERER_SEARCH_QUERY);
	#print "Looking for $REFERER in st.refers table\n"; 
	$sth->execute($REFERER) or die "Couldn't execute statement: " . $sth->errstr;
	@REFERER_DATA = $sth->fetchrow_array();
	$REFERER_ID = $REFERER_DATA[0];
	#print "First pass: referer id = $REFERER_ID ?\n";

	if ($sth->rows == 0) {
		print "No previous refer record found in st.refers table for $REFERER.\n";
# This should create a record in the st.refers automatically.
		system("$CURL_COMMAND http://www.shermanstravel.com/top25/signup/?refer=$REFERER > /dev/null 2>&1");
		print "Lets see if we can create a new referer: $CURL_COMMAND http://www.shermanstravel.com/top25/signup/?refer=$REFERER\n";
# Lets introduce a little delay, giving the database some time to update.
		sleep(3);
# Check again
		#print "Looking for $REFERER in st.refers table (Second Try)\n";
		$sth = $dbh->prepare($REFERER_SEARCH_QUERY);
		$sth->execute($REFERER) or die "Couldn't execute statement: " . $sth->errstr;
		@REFERER_DATA = $sth->fetchrow_array();
		$REFERER_ID = $REFERER_DATA[0];
			if ($sth->rows == 0) {
				#print "Can not create record, faking a response\n";
				$REFERER_ID = '0';
				return($REFERER_ID);
			} else {
				#print "Found a valid referrer id: $REFERER_ID\n";
				return($REFERER_ID);
			}
	} else {
		#print "Found a valid referrer id: $REFERER_ID\n"; 
		return($REFERER_ID);
	}

}
