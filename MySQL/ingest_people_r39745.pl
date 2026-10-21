#!/usr/bin/perl

use strict;
use warnings;

require DBD::mysql;

my $INPUT_FILE = $ARGV[0];
#my $LIFESCRIPT_REFERER_ID = "15452254";  #Lifescript is id 15452254 from st.refers table
my $LIFESCRIPT_REFERER_ID = "29445317";  #Lifescript is id 29445317 from st.refers table
my $LIFESCRIPT_HEADER = "Lifescript_Sherman Travel";
my $DBH;                                # Generic DB Handle
my $STH;
my $FOUND_COUNT = 0;
my $NEW_COUNT = 0;
my $INVALID_COUNT = "0";
my $RESUBSCRIBE_COUNT = "0";
my $HOME = "/home/mking";
my %OPTIONS;
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "db4";          # 10.131.125.94
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
my $FATAL_ERROR;
my $ERROR_INFO;

# Variables which should come from input file
my $FIRST_NAME; 				# st.people first_name
my $LAST_NAME;					# st.people last_name
my $EMAIL;						# st.people email
my $ZIP;						# st.people_addresses postal_code
my $IP;							# Planning to drop this
my $TIMESTAMP;					# Planning to drop this
#my $ZIP;						# postal_code in st.people_addresses? (or st.addresses?)
#my $IP;						# ip in st.refers_people? 

## Datbase fields I need to populate
# st.people_addresses
# my $PA_ID;  					# Should be auto incremented
my $PA_ADDRESS = "NULL";
my $PA_ADDRESS_2 = "NULL";
my $PA_CITY = "NULL";
my $PA_STATE_OR_TERRITORY = "NULL";
my $PA_POSTAL_CODE;				# $ZIP from input file
my $PA_COUNTRY_ID = "NULL";
my $PA_PHONE = "NULL";
my $PA_FAX = "NULL";
my $PA_CITY_ID = "NULL";
my $PA_STATE_ID = "NULL";
my $PA_URL = "NULL";

# st.people
my $P_ID;  					# Should be auto incremented
my $P_VISITOR_ID = "NULL";
my $P_ADDRESS_ID;				# Must match id from st.people_addresses
my $P_FIRST_NAME;				# $FIRST_NAME from input file
my $P_LAST_NAME;				# $LAST_NAME from input file
my $P_EMAIL;					# $EMAIL from input file
my $P_CREATED = "NOW()";
my $P_MODIFIED = "NOW()";
my $P_REFER_ID = $LIFESCRIPT_REFERER_ID;
my $P_SOURCE_LIFESCRIPT = "www.lifescript.com";
my $P_IS_ADMINISTRATOR = "NULL";
my $P_USERNAME = "NULL";
my $P_PASSWORD = "NULL";
my $P_RECOVERY_REQUESTED_AT = "NULL";		
my $P_REGISTERED_AT	= "NULL";	# Appearently only important to MyTravel
my $P_CONFIRMED_AT = "NULL";	# Appearently only important to MyTravel 
my $P_FACEBOOK_ID = "NULL";

# st.subscriptions
my $S_PERSON_ID; 				# Must match P_ID (st.people id)
my $S_SUBSCRIPTION_TYPE_ID = "2"; # Top25 subscription
my $S_CREATED = "NOW()";
my $S_MODIFIED = "NOW()";
my $S_IS_UNSUBSCRIBED = "0";
my $S_UNSUBSCRIBE_REASON_ID = "NULL";
my $S_SOURCE_ID = "7";			# "External Ingestion" from st.susbscription_sources table
my $S_ID;						# Should be auto incremented.

# MYSQL queries and Updates.
my $EMAIL_SEARCH_QUERY = "SELECT id, email FROM people WHERE email = ? ";
my $SUBSCRIPTION_SEARCH_QUERY = "SELECT subscription_type_id, is_unsubscribed FROM subscriptions WHERE subscription_type_id = '$S_SUBSCRIPTION_TYPE_ID' AND person_id = ? ";
my $S_IS_UNSUBSCRIBED_UNKNOWN;
my $SUBSCRIBE_TOP25 = "UPDATE subscriptions SET is_unsubscribed = '0' WHERE subscription_type_id = '$S_SUBSCRIPTION_TYPE_ID' AND person_id = ? ";
my $ADD_PA_ADDRESS_ENTRY = "INSERT INTO people_addresses VALUES(NULL,'$PA_ADDRESS','$PA_ADDRESS_2','$PA_CITY','$PA_STATE_OR_TERRITORY','?','$PA_COUNTRY_ID','$PA_PHONE','$PA_FAX','$PA_FAX','$PA_CITY_ID','$PA_STATE_ID','$PA_URL')";
my @PEOPLE_DATA;
my @SUBSCRIPTION_DATA;


# Sample Lifescript data
# Hayden,Fitzgerald,hfitzgerald@lifescript.com,92691,216.237.23.221,20110531105030
# $FIRST_NAME,$LAST_NAME,$EMAIL,$ZIP,$IP,$TIMESTAMP

#
# 06/07/11
#mysql> SELECT * FROM refers WHERE refer like "%lifescript%"\G
#*************************** 1. row ***************************
#id: 29445312
# refer: D25-LifeScript-t25
# company: NULL
# campaign: NULL
# date_text: NULL
# deal: NULL
# test_code: NULL
# created: 2011-05-31 15:53:49
# modified: 2011-05-31 15:53:49
# *************************** 2. row ***************************
# id: 29445317
# refer: D25-LifeScript-t25
# company: NULL
# campaign: NULL
# date_text: NULL
# deal: NULL
# test_code: NULL
# created: 2011-05-31 16:41:33
# modified: 2011-05-31 16:41:33

# Open the file with the mysql password
open (FH, "$OPTIONS{db_password_file}");
flock FH,2;
$OPTIONS{mysql_password}=<FH>;
close FH;
chomp $OPTIONS{mysql_password};

# Read in the FTP file
open(INPUT_FILE, "$INPUT_FILE");

while(<INPUT_FILE>) {
	chomp;
	if(/$LIFESCRIPT_HEADER/) {
		print "Skipping Header Line: $LIFESCRIPT_HEADER\n";
		next;
	}
	# Lets do some input validation
	if($_ =~ /\w*,\w*,\w*@\w*.\w*,\d*,\d*\.\d*\.\d*\.\d*,\d*/) {
	# Parse data by splitting on commas
	($FIRST_NAME,$LAST_NAME,$EMAIL,$ZIP,$IP,$TIMESTAMP) = split(/,/);
	#print "My name is $FIRST_NAME $LAST_NAME.  My Email is $EMAIL.  My Zip is $ZIP.\n";
	}
 	# Do not process record unless it has a valid email and zipcode
	unless($EMAIL) {
		print "Incomplete Record, no email.\n";
		++$INVALID_COUNT;
		next;
	}
	unless($ZIP) {
		print "Incomplete Record, no zip.\n";
		++$INVALID_COUNT;
		next;
	}

	# if our database handle cannot connect, spit out an error string and die
	if (!($DBH = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}","$OPTIONS{db_username}","$OPTIONS{mysql_password}"))) {
	    $FATAL_ERROR=1;
		    $ERROR_INFO.= "DB connect error! $DBI::errstr";
			    return 1;
	}

	$STH = $DBH->prepare($EMAIL_SEARCH_QUERY);
	$STH->execute($EMAIL);

	while (@PEOPLE_DATA = $STH->fetchrow_array()) {
		++$FOUND_COUNT;
		$P_ID = $PEOPLE_DATA[0];
		$P_EMAIL = $PEOPLE_DATA[1];
		print "FOUND $P_EMAIL with ID $P_ID\n";
	# OK. So lets make sure they are subscribed for Top25 
		$STH = $DBH->prepare($SUBSCRIPTION_SEARCH_QUERY);
		$STH->execute($P_ID);
		@SUBSCRIPTION_DATA = $STH->fetchrow_array();
		#$S_SUBSCRIPTION_TYPE_ID = $SUBSCRIPTION_DATA[0];
		$S_IS_UNSUBSCRIBED_UNKNOWN = $SUBSCRIPTION_DATA[1];
		unless($SUBSCRIPTION_DATA[1] == '0') {
			print "...User previously subscribed to Top25, but needs to be re-subscribed.\n";
			$STH = $DBH->prepare($SUBSCRIBE_TOP25);
			$STH->execute($P_ID);
			++$RESUBSCRIBE_COUNT;
		} else {
			print "...User already subscribed to Top25.  No action needed.\n";
		}
	} 
	if ($STH->rows == 0) {
		print "No record found in st.people table for $EMAIL.\n";
	# O.K.  Here is the import I guess.
		#$STH = $DBH->prepare($ADD_PA_ADDRESS_ENTRY);
		#$STH->execute($$ZIP);
		# Check status by seeing how many rows were returned?

		++$NEW_COUNT;
	}
}

print "\n\nTotals:\n";
print "Found count  = $FOUND_COUNT\n";
print "New count  = $NEW_COUNT\n";
print "Re-subscribe count = $RESUBSCRIBE_COUNT\n";
print "Invalid Record Count = $INVALID_COUNT\n";
