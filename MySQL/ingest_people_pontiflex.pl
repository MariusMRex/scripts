#!/usr/bin/perl

use strict;
use warnings;

require DBD::mysql;

my $CURL_COMMAND = "/usr/bin/curl";		# Date command binary
my $DATE_COMMAND = "/bin/date";		# Date command binary
my $FILE_DATE = `$DATE_COMMAND +%Y%m%d`;	# Datestamp pre-appended to FTP files
	chomp($FILE_DATE);
my $HOME = "/home/pflex";
#my $INPUT_FILE = $ARGV[0];
my $INPUT_FILE = "$HOME/$FILE_DATE.Pontiflex.csv";
my $REFERER_PREFIX = "D25-Pontiflex_";
my $REFERER_ID;  						# Needs to be determined dynamically.
#my $FILE_HEADER = "First,Last,Email ,Zip,IP,Timestamp,Source";	# First Line of every CSV file 
my $FILE_HEADER = "First,Last,Email,Zip,Source";	# First Line of every CSV file 
my $DBH;                                # Generic DB Handle
my $STH;								# generic Statement Handler
my $INSERT_COUNT = 0;					# Reset Counter for new subscribers imported
my $INVALID_COUNT = "0";				# Reset Counter for invalid records found
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
	    $HOUR = "0$MIN";
}
if(length($SEC) == "1") {
	    $SEC = "0$SEC";
}
my $DATE = "$YEAR-$MON-$MDAY $HOUR:$MIN:$SEC";	# Mysql compatable date format
#my $DATE = "2011-06-26 07:7:01";

# Mail SETTINGS
my $TO = 'mking@shermanstravelmedia.com';
my $FROM = 'noreply@shermanstravelmedia.com';
my $SUBJECT = 'Daily output from ingest_people_pontiflex.pl';


# Variables which should come from input file
my $FIRST_NAME; 				# st.people first_name
my $LAST_NAME;					# st.people last_name
my $EMAIL;						# st.people email
my $ZIP;						# st.people_addresses postal_code
my $IP;							# Planning to drop this
my $TIMESTAMP;					# Planning to drop this
my $SOURCE;						# Who gave us the lead?
my $REFERER;					# $SOURCE as referer from st.referer
my $NULL;						# Empty padding for NULL Values

# st.signup_datastores
my $SD_ID;						# Should be Auto Increment
my $SD_CACHE_KEY;				# Without this, the script that processes the st.signup_datastores table will ignore the entry.  Must be uniqe for each record
my %SD_DATA;
$SD_DATA{first_array} = "a:12:{";	# I will have 12 elements
#$SD_DATA{email};				# s:5:"email";s:?:"$EMAIL";'
#$SD_DATA{postal_code}; 			# s:11:"postal_code";s:?:"$ZIP";
#$SD_DATA{refer} = 's:5:"refer";s:18:"D25-LifeScript-t25";';
#$SD_DATA{source_url} = 's:10:"source_url";s:68:"http://lsa.lifescript.com/advantage/hp8831/main.aspx?utm_campaign=hp";';
$SD_DATA{source_url} = 's:10:"source_url";s:25:"http://www.pontiflex.com/";';
$SD_DATA{subscription_source_id} = 's:22:"subscription_source_id";i:7;'; 	# Subscription_source_id 7 is 'external; ingestion'
#$SD_DATA{subscription_date} = "s:17:\"subscription_date\";s:?:\"$DATE\";";
$SD_DATA{visitor} = 's:10:"visitor_id";N;';
$SD_DATA{uuid} = 's:4:"uuid";N;';
$SD_DATA{email_type} = 's:10:"email_type";s:17:"top25WelcomeEmail";';
#$SD_DATA{magazine_sourcekey} = 's:18:"magazine_sourcekey";s:6:"O1A019";';
#$SD_DATA{firstname}; 			# 's:9:"firstname";s:?:"$FIRST_NAME";'
#$SD_DATA{lastname}; 			# 's:8:"lastname";s:?:"$LAST_NAME";'
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
#my $SUBSCRIPTION_SEARCH_QUERY = "SELECT subscription_type_id, is_unsubscribed FROM subscriptions WHERE subscription_type_id = '$S_SUBSCRIPTION_TYPE_ID' AND person_id = ? ";
#my $S_IS_UNSUBSCRIBED_UNKNOWN;
#my $SUBSCRIBE_TOP25 = "UPDATE subscriptions SET is_unsubscribed = '0' WHERE subscription_type_id = '$S_SUBSCRIPTION_TYPE_ID' AND person_id = ? ";
#my $ADD_PA_ADDRESS_ENTRY = "INSERT INTO people_addresses VALUES(NULL,'$PA_ADDRESS','$PA_ADDRESS_2','$PA_CITY','$PA_STATE_OR_TERRITORY','?','$PA_COUNTRY_ID','$PA_PHONE','$PA_FAX','$PA_FAX','$PA_CITY_ID','$PA_STATE_ID','$PA_URL')";
#my @PEOPLE_DATA;
#my @SUBSCRIPTION_DATA;
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
    # New rules for post code 5 or more alpha-numeric characters or a dash - Marius 2011-12-28
	if(/.*?,.*?,[\w.%+-]+@[\w.-]+\.[\w]{2,4},[\w-\-]{5,},\w+-\w+/) {
		# Parse data by splitting on commas
		#($FIRST_NAME,$LAST_NAME,$EMAIL,$ZIP,$IP,$TIMESTAMP,$SOURCE) = split(/,/);
		($FIRST_NAME,$LAST_NAME,$EMAIL,$ZIP,$SOURCE) = split(/,/);
		print "My name is $FIRST_NAME $LAST_NAME.  My Email is $EMAIL.  My Zip is $ZIP. My Source is $SOURCE\n";
	} else {
		print MAIL "Line did not match: $_\n";
	}
 	# Do not process record unless it has a valid email, zipcode, or source
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
	unless($SOURCE) {
		print MAIL "Incomplete Record, no source.\n";
		next;
	}
# Pontflex truncates zipcodes that start with a '0'
	if(length($ZIP) == '4') {
		#print "Padding four character zipcode ($ZIP) with a '0' ";
		$ZIP = "0" . "$ZIP";
		#print "--newzip: $ZIP\n";
	}
# Need to do so pre-processing on the referer varaible
	#chomp($SOURCE);
# Strip out MOB Header, if it exists
	if($SOURCE =~ /^(MOB|mob)-(\w*$)/) {
		$SOURCE = $2;
	}
	$REFERER = "$REFERER_PREFIX" . "$SOURCE";
	#print "Found $REFERER, attempting to verify in database...\n";

	# if our database handle cannot connect, spit out an error string and die
	if (!($DBH = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}","$OPTIONS{db_username}","$OPTIONS{mysql_password}"))) {
	    $FATAL_ERROR=1;
		    $ERROR_INFO.= "DB connect error! $DBI::errstr";
			    return 1;
	}

# We want a valid $REFERER_ID, so lets see if we can find one.
	verify_referer($REFERER);
	#print "Using referer_id = $REFERER_ID and moving on\n";

	# Populate the fields of st.signup_datastores that we could not populate before
	$LEN_EMAIL = length($EMAIL);	
	$LEN_POSTAL_CODE = length($ZIP);
	$LEN_DATE = length($DATE);
	$LEN_FIRST_NAME = length($FIRST_NAME);
	$LEN_LAST_NAME = length($LAST_NAME);
	$LEN_REFERER = length($REFERER);
	$LEN_REFERER_ID = length($REFERER_ID);
	$SD_DATA{email} = "s:5:\"email\";s:$LEN_EMAIL:\"$EMAIL\";";
	$SD_DATA{postal_code} = "s:11:\"postal_code\";s:$LEN_POSTAL_CODE:\"$ZIP\";";
	$SD_DATA{referer} = "s:5:\"refer\";s:$LEN_REFERER:\"$REFERER\";";
	$SD_DATA{subscription_date} = "s:17:\"subscription_date\";s:$LEN_DATE:\"$DATE\";";
	$SD_DATA{refer_id} = "s:8:\"refer_id\";s:$LEN_REFERER_ID:\"$REFERER_ID\";";
	$SD_DATA{firstname} = "s:9:\"firstname\";s:$LEN_FIRST_NAME:\"$FIRST_NAME\";";
	$SD_DATA{lastname} = "s:8:\"lastname\";s:$LEN_LAST_NAME:\"$LAST_NAME\";";
	$SD_CACHE_KEY = randomString(25);
	$SD_DATA_COMPLETE = "$SD_DATA{first_array}$SD_DATA{email}$SD_DATA{postal_code}$SD_DATA{referer}$SD_DATA{source_url}$SD_DATA{subscription_source_id}$SD_DATA{subscription_date}$SD_DATA{visitor}$SD_DATA{refer_id}$SD_DATA{uuid}$SD_DATA{email_type}$SD_DATA{firstname}$SD_DATA{lastname}$SD_DATA{end_array}";
# If we remove the $SD_DATA{email_type} we no longer send welcome emails.  Most of time time we wanty to send welcome emails
	#$SD_DATA_COMPLETE = "$SD_DATA{first_array}$SD_DATA{email}$SD_DATA{postal_code}$SD_DATA{referer}$SD_DATA{source_url}$SD_DATA{subscription_source_id}$SD_DATA{subscription_date}$SD_DATA{visitor}$SD_DATA{refer_id}$SD_DATA{uuid}$SD_DATA{firstname}$SD_DATA{lastname}$SD_DATA{end_array}";
	$NEW_RECORD_INSERT = "INSERT INTO signup_datastores VALUES(NULL,'$SD_CACHE_KEY','$SD_DATA_COMPLETE','$SD_UPDATED','$SD_PROCESSED')";
	#print MAIL "Inserting new Record: VALUES(NULL,'$SD_CACHE_KEY','$SD_DATA_COMPLETE','$SD_UPDATED','$SD_PROCESSED'\n";
	#print MAIL "Inserting new Record: $SD_DATA{email}\n";

	$STH = $DBH->prepare($NEW_RECORD_INSERT);
	$STH->execute() or die "Couldn't execute statement: " . $STH->errstr;
	++$INSERT_COUNT;
	# backend only processes 500 log lines every 5 minutes, so lets throttle ingestion
	sleep 1;
}

print MAIL "Record Insert count  = $INSERT_COUNT\n";
print MAIL "Invalid Record Count = $INVALID_COUNT\n";

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
	$STH = $DBH->prepare($REFERER_SEARCH_QUERY);
	#print "Looking for $REFERER in st.refers table\n"; 
	$STH->execute($REFERER) or die "Couldn't execute statement: " . $STH->errstr;
	@REFERER_DATA = $STH->fetchrow_array();
	$REFERER_ID = $REFERER_DATA[0];
	#print "First pass: referer id = $REFERER_ID ?\n";

	if ($STH->rows == 0) {
		print "No previous refer record found in st.refers table for $REFERER.\n";
# This should create a record in the st.refers automatically.
		system("$CURL_COMMAND http://www.shermanstravel.com/top25/signup/?refer=$REFERER > /dev/null 2>&1");
		print "Lets see if we can create a new referer: $CURL_COMMAND http://www.shermanstravel.com/top25/signup/?refer=$REFERER\n";
# Lets introduce a little delay, giving the database some time to update.
		sleep(3);
# Check again
		#print "Looking for $REFERER in st.refers table (Second Try)\n";
		$STH = $DBH->prepare($REFERER_SEARCH_QUERY);
		$STH->execute($REFERER) or die "Couldn't execute statement: " . $STH->errstr;
		@REFERER_DATA = $STH->fetchrow_array();
		$REFERER_ID = $REFERER_DATA[0];
			if ($STH->rows == 0) {
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
