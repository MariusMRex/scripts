#!/usr/bin/perl

use strict;
use warnings;

require DBD::mysql;

#my $CURL_COMMAND = "/usr/bin/curl";		# Date command binary
my $DATE_COMMAND = "/bin/date";		# Date command binary
my $FILE_DATE = `$DATE_COMMAND +%Y%m%d`;	# Datestamp pre-appended to FTP files
	chomp($FILE_DATE);
my $HOME = "/home/bwiz";
my $INPUT_FILE = $ARGV[0];
#my $INPUT_FILE = "$HOME/SHERMANS_TRAVEL_$FILE_DATE.csv";
my $REFERER = "D25-BookingWiz";
my $REFERER_ID = "29590707"; 			# I created this referrer by hand via `curl http://www.shermanstravel.com/top25/signup/?refer=D25-BookingWiz`
#my $FILE_HEADER = "Opt_Url,Firstname,Lastname,Email,Zip,Address,CityFrom,CityTo,FromDate,ReturnDate,IP,SubSource";	# First Line of every CSV file 
my $FILE_HEADER = "Opt_Url,Firstname,Lastname,Email,Address,CityFrom,CityTo,FromDate,ReturnDate,IP,SubSource";	# First Line of every CSV file 
my $DBH;                                # Generic DB Handle
my $STH;								# generic Statement Handler
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
my $SUBJECT = 'Daily output from ingest_people_BookingWiz.pl';


# Variables which should come from input file
# Opt_Url,Firstname,Lastname,Email,Zip,Address,CityFrom,CityTo,FromDate,ReturnDate,IP,SubSource
my $OptURL;
my $FIRST_NAME; 				# st.people first_name
my $LAST_NAME;					# st.people last_name
my $EMAIL;						# st.people email
my $EMAIL2;						# USed to check for duplicate emails.
my $ZIP;						# st.people_addresses postal_code
my $ADDRESS;					# Often NULL
my $CITY_FROM;					# Flight information that does not mean much to this script
my $CITY_TO;					# Flight information that does not mean much to this script
my $FROM_DATE;					# Flight information that does not mean much to this script
my $RETURN_DATE;					# Flight information that does not mean much to this script
my $IP;							# Planning to drop this
my $SUB_SOURCE;					# Often NULL
my $NULL;						# Empty padding for NULL Values

# st.signup_datastores
my $SD_ID;						# Should be Auto Increment
my $SD_CACHE_KEY;				# Without this, the script that processes the st.signup_datastores table will ignore the entry.  Must be uniqe for each record
my %SD_DATA;
$SD_DATA{first_array} = "a:12:{";	# I will have 12 elements
#$SD_DATA{email};				# s:5:"email";s:?:"$EMAIL";' - Take from input file
#$SD_DATA{postal_code}; 			# s:11:"postal_code";s:?:"$ZIP"; - Take from input file
#$SD_DATA{refer} = 's:5:"refer";s:18:"D25-LifeScript-t25";'; - Will need to make something up
$SD_DATA{source_url} = 's:10:"source_url";s:26:"http://www.bookingwiz.com/";';
$SD_DATA{subscription_source_id} = 's:22:"subscription_source_id";i:7;'; 	# Subscription_source_id 7 is 'external; ingestion'
#$SD_DATA{subscription_date} = "s:17:\"subscription_date\";s:?:\"$DATE\";"; - Take from current time running script
$SD_DATA{visitor} = 's:10:"visitor_id";N;';
$SD_DATA{uuid} = 's:4:"uuid";N;';
$SD_DATA{email_type} = 's:10:"email_type";s:17:"top25WelcomeEmail";';
#$SD_DATA{magazine_sourcekey} = 's:18:"magazine_sourcekey";s:6:"O1A019";'; - Not needed
#$SD_DATA{firstname}; 			# 's:9:"firstname";s:?:"$FIRST_NAME";' - Take from input file
#$SD_DATA{lastname}; 			# 's:8:"lastname";s:?:"$LAST_NAME";'	- Take From input file
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
my $DUPLICATE_CHECK_QUERY = "SELECT p.email FROM people AS p, subscriptions AS s WHERE p.id = s.person_id AND s.subscription_type_id = '2' AND s.is_unsubscribed != '1' AND p.email = ?";
my $NEW_RECORD_INSERT; 			# "INSERT INTO signup_datastores VALUES(NULL,'$SD_CACHE_KEY','SD_DATA_COMPLETE','$SD_UPDATED','$SD_PROCESSED')";

# Sample BookingWiz Data
# Opt_Url,Firstname,Lastname,Email,Zip,Address,CityFrom,CityTo,FromDate,ReturnDate,IP,SubSource
#http://www.bookingwiz.com/coreg/TravelSecrets/Subscribe.aspx?Page=TravelSecretsEmailList,,,deshkarthik@gmail.com,560023,bangalore,,,12/3/2011 12:00:00 AM,,10.0.1.35,
#http://www.bookingwiz.com/coreg/TravelSecrets/Subscribe.aspx?Page=TravelSecretsEmailList,,,lilycat1@gmail.com,19020,Bensalem,,,12/3/2011 12:00:00 AM,,10.0.1.35,
#http://www.bookingwiz.com/coreg/TravelSecrets/Subscribe.aspx?Page=TravelSecretsEmailList,,,Caramelkiss6078@yahoo.com,46224,Indianapolis,,,12/2/2011 12:00:00 AM,,10.0.1.35,
#http://www.bookingwiz.com/coreg/TravelSecrets/Subscribe.aspx?Page=TravelSecretsEmailList,,,dmartinbookingwiz@gmail.com,19019,Philadelphia,,,12/3/2011 12:00:00 AM,,10.0.1.35,
#http://www.bookingwiz.com/coreg/TravelSecrets/Subscribe.aspx?Page=TravelSecretsEmailList,,,megadem@yahoo.com,18968,Spinnerstown,,,12/3/2011 12:00:00 AM,,10.0.1.35,
#http://www.bookingwiz.com/coreg/TravelSecrets/Subscribe.aspx?Page=TravelSecretsEmailList,,,egalima@hotmail.com,90806,long beach,,,12/3/2011 12:00:00 AM,,10.0.1.35

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
#print "Reading in $INPUT_FILE\n";

while(<INPUT_FILE>) {
	chomp;
	if(/$FILE_HEADER/) {
		print MAIL "Skipping Header Line: $FILE_HEADER\n";
		print "Skipping Header Line: $FILE_HEADER\n";
		next;
	}
# Lets remove some unfortunate characters.
	s/[\'|\"|\%|\?+|\s]//g;
	# Lets do some input validation
    # New rules for post code 4 or more alpha-numeric characters or a dash
    # BookinWiz gets a small exception since they sometimes remove the leading zeros, which I add below -Marius 2011-12-28
	if(/(http|https):\/\/[\w\-_]+(\.[\w\-_]+)+([\w\-\.,@?^=%&amp;:\/~\+#]*[\w\-\@?^=%&amp;\~\+#])?,[\w\.\-]+,,[\w.%+-]+@[\w.-]+\.[\w]{2,4},[\w\-]{2,},.*/) {
		($OptURL,$FIRST_NAME,$LAST_NAME,$EMAIL,$ZIP,$ADDRESS,$CITY_FROM,$CITY_TO,$FROM_DATE,$RETURN_DATE,$IP,$SUB_SOURCE) = split(/,/);
		print "My name is $FIRST_NAME $LAST_NAME.  My Email is $EMAIL.  My Zip is $ZIP.\n";
	} else {
		print MAIL "Line did not match: $_\n";
		++$INVALID_COUNT;
		print "Line did not match: $_\n";
		next;
	}
 	# Do not process record unless it has a valid email and zipcode.
	unless($EMAIL) {
		#print MAIL "Incomplete Record, no email.\n";
		print "Incomplete Record, no email.\n";
		++$INVALID_COUNT;
		next;
	}
	unless($ZIP) {
		#print MAIL "Incomplete Record, no zip.\n";
		print "Incomplete Record, no zip.\n";
		++$INVALID_COUNT;
		next;
	}
# Pontflex truncates zipcodes that start with a '0'
	while(length($ZIP) < '4') {
		#print "Padding four character zipcode ($ZIP) with a '0' ";
		$ZIP = "0" . "$ZIP";
		print "--newzip: $ZIP\n";
	}
	# if our database handle cannot connect, spit out an error string and die
	if (!($DBH = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}","$OPTIONS{db_username}","$OPTIONS{mysql_password}"))) {
	    $FATAL_ERROR=1;
		    $ERROR_INFO.= "DB connect error! $DBI::errstr";
			    return 1;
	}
	# Need to check that this email is not already subscribed
	#$STH = $DBH->prepare($DUPLICATE_CHECK_QUERY);
	#$STH->execute($EMAIL) or die "Couldn't execute statement: " . $STH->errstr;
	#$EMAIL2 = $STH->fetchrow();
	#unless($STH->rows == 0) {
	#	print MAIL "$EMAIL is already subscribed, skipping";
	#	print "$EMAIL is already subscribed, skipping";
	#	++$DUPLICATE_COUNT;
	#	next;
	#}
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
#print MAIL "Duplicate email Count = $DUPLICATE_COUNT\n";
#print "Record Insert count  = $INSERT_COUNT\n";
#print "Invalid Record Count = $INVALID_COUNT\n";

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
