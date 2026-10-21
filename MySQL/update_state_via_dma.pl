#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## Complaints surface that state counts are 
## much less then the sum of DMA's we logically include.
## Lets walk though st.derived_address and compare to 
## st.dma_zip and see if we can right any of this
## Marius 2011-09-29

## So the plan, as it stands:
## Query st.derived_dma for person_id and derived_dma
## use person_id as key in st.people tables to grab address_id
## lookup derived_dma in st.dma_zip, key is dma, return state
## now update st.people_addresses field state_or_territory by key address_id. 

## This script officially "works" buit given the lareg amount
## of invalid or incomplete records it encounters the script itself
## tends to produce a lot of errors when it runs.  I have tried to
## minimize the errors, but usually I just route STDERR to 
## /dev/null when I am running this live and just wait for
## The pretty summary at the end.

my $DBH;                             	# Generic DB Handle This will be db4 for reading
my $DBH2;                             	# Generic DB Handle This will be mmwfor writing
my $RC;									# Return Code for DBI connection
my $STH;
my $HOME = "/home/mking";
my %OPTIONS;
## We will need to start queries on db4 as that is where
## st.derived_address lives. Will need to set to 
## mmw last in the script
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "db4";          # 10.131.125.94
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
my $FATAL_ERROR;
my $ERROR_INFO;

my @SUBSCRIBER_LIST;
my $PERSON_ID;
my $DMA;
my $ADDRESS_ID;
my $STATE_ABBREVIATION;
my $CURRENT_STATE_ABBREVIATION;			# What state designation, if anything is already in the database for the given subscriber?
# Some Counters
my $TOTAL_ACTIVE_SUBSCRIBERS = "0";
my $INVALID_PERSON_ID_OR_DMA = "0";
my $INVALID_ADDRESS_ID = "0";
my $NO_ADDRESS_ID = "0";
my $NULL_ADDRESS_ID = "0";
my $NULL_STATE_FROM_DMA = "0";
my $CORRECT_STATE_CODE = "0";
my $RECORDS_TO_UPDATE = "0";
my $UPDATED_RECORDS = "0";

# MYSQL queries and Updates.
#my $SUBSCRIBER_QUERY = "SELECT person_id,derived_dma FROM derived_address ORDER BY RAND() LIMIT 10";
my $SUBSCRIBER_QUERY = "SELECT person_id,derived_dma FROM derived_address";
# WHERE id is person_id from $SUBSCRIBER_QUERY
my $ADDRESS_ID_QUERY = "SELECT address_id FROM people WHERE id = ?";
# WHERE dma is derived_dma FROM $SUBSCRIBER_QUERY
my $STATE_QUERY = "SELECT state FROM dma_zip WHERE dma = ?";
# For fun lets verify how much would change before we do an update
my $VERIFY_STATE_QUERY = "SELECT state_or_territory FROM people_addresses WHERE id = ?";
# WHERE state_or_territory FROM $STATE_QUERY AND id is address_id from $ADDRESS_ID_QUERY
my $PEOPLE_ADDRESSEES_UPDATE = "UPDATE people_addresses SET state_or_territory = ? WHERE id = ?";

print "Grabbing password file\n";
# Open the file with the mysql password
open (FH, "$OPTIONS{db_password_file}");
flock FH,2;
$OPTIONS{mysql_password}=<FH>;
close FH;
chomp $OPTIONS{mysql_password};

print "Initiating database connection.\n";
# if our database handle cannot connect, spit out an error string and die
if (!($DBH = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}","$OPTIONS{db_username}","$OPTIONS{mysql_password}"))) {
    $FATAL_ERROR=1;
    $ERROR_INFO.= "DB connect error! $DBI::errstr";
    return 1;
}

# I still suck at hashes, so lets work around that
# from brevity's shake
open(SUBSCRIBERS, ">/tmp/subscribers_n_dma.txt");

# O.K.  Lets get a list of active users
print "Lets grab the list of people from derived_address.\n";
$STH = $DBH->prepare($SUBSCRIBER_QUERY);
$STH->execute() or die "Couldn't execute statement: " . $STH->errstr;
while (@SUBSCRIBER_LIST = $STH->fetchrow_array()) {
	$PERSON_ID = $SUBSCRIBER_LIST[0];
	$DMA = $SUBSCRIBER_LIST[1];
	print SUBSCRIBERS "$PERSON_ID,$DMA\n";
	++$TOTAL_ACTIVE_SUBSCRIBERS;
}
# Close the file handle we opened for writing for neetness sake
close(SUBSCRIBERS);
print "\n";

# Open a new file handle for reading
open(SUBSCRIBER_LISTING, "/tmp/subscribers_n_dma.txt");
# We can write out to this new file
open(ADDRESS_WITH_DMA, ">/tmp/address_n_dma.txt");
#open(NO_STATE_BY_DMA, ">/tmp/no_state_by_dma.txt");

print "So lets gets some info on these subscribers\n";
while(<SUBSCRIBER_LISTING>) {
	chomp;
# Valid person_id's and dma's are multiple digits ('0' is not an option)
	if(/\d\d+,\d\d+/) {
# Parse data by splitting on commas
		($PERSON_ID,$DMA) = split(/,/);
		#print "My person_id is $PERSON_ID and I belong to this dma: $DMA\n";
	} else {
		#print "rejecting $_ as invalid. Either the person_id or the dma is corrupted or non-existant\n";
		++$INVALID_PERSON_ID_OR_DMA;
		next;
	}
	# So lets find the address_id that matches this person_id
	$STH = $DBH->prepare($ADDRESS_ID_QUERY);
	$STH->execute($PERSON_ID) or die "Couldn't execute statement: " . $STH->errstr;
	$ADDRESS_ID = $STH->fetchrow();

# Some people records have no address ID
	if($STH->rows == 0) {
		#print "Did not return an address_id for $PERSON_ID\n\n";
		++$NO_ADDRESS_ID;
		next;
	}
# If address_id is 'NULL' there is no point in proceeeding
# and we will have nothing to update later
	if($ADDRESS_ID eq "NULL") {
		#print "Got a NULL address for $PERSON_ID\n\n";
		++$NULL_ADDRESS_ID;
		next;
	}
# Lets just validate our input
	unless($ADDRESS_ID =~ /\d\d+/) {
		#print "Invalid Address ID: $ADDRESS_ID\n\n";
		++$INVALID_ADDRESS_ID;
		next;
	}
# Perhaps it is safe to try to print this now.
	#print "PID: $PERSON_ID - ADD_ID: $ADDRESS_ID - ";

# Now lets grab the state from st.dma_zips
	$STH = $DBH->prepare($STATE_QUERY);
	$STH->execute($DMA) or die "Couldn't execute statement: " . $STH->errstr;
	$STATE_ABBREVIATION = $STH->fetchrow();

# We get a lot of NULL responces from state queries
	if($STATE_ABBREVIATION eq "NULL") {
		#print "NULL state entry returned from query by DMA, Kinda stuck then.\n\n";
		++$NULL_STATE_FROM_DMA;
		next;
	}

# if the DMA does not point to a US state, we cannot use it.
	if ($STH->rows == 0) {
		#print "Did not get a valid state for $DMA\n\n";
		++$NULL_STATE_FROM_DMA;
		#print NO_STATE_BY_DMA "$PERSON_ID,$DMA,$ADDRESS_ID\n";
		next;
	}
# So in theory we should be able to print out our state output now
	#print " state: $STATE_ABBREVIATION -";

# Lets verify the necessity of an update
# First off, do we have an address ID to work with?
	if($ADDRESS_ID) {
		$STH = $DBH->prepare($VERIFY_STATE_QUERY);
		$STH->execute($ADDRESS_ID) or die "Couldn't execute statement: " . $STH->errstr;
		$CURRENT_STATE_ABBREVIATION = $STH->fetchrow();
		if($STH->rows == 0 || $CURRENT_STATE_ABBREVIATION eq "NULL") {
			# If we have no state code, we should try to update the record.
			#print "Query for existant state_or_territory had no results for $ADDRESS_ID\n";
			print ADDRESS_WITH_DMA "$PERSON_ID,$DMA,$ADDRESS_ID,$STATE_ABBREVIATION\n";
			#print " Adding this for update: $PERSON_ID,$DMA,$ADDRESS_ID,$STATE_ABBREVIATION\n";
			++$RECORDS_TO_UPDATE;
		}
		if($STATE_ABBREVIATION eq $CURRENT_STATE_ABBREVIATION) {
			++$CORRECT_STATE_CODE;
			#print " Looks Good: $PERSON_ID,$DMA,$ADDRESS_ID,$STATE_ABBREVIATION\n";
		}	 else {
# Write out our new data to another text file, as we assume the state code is wrong
			print ADDRESS_WITH_DMA "$PERSON_ID,$DMA,$ADDRESS_ID,$STATE_ABBREVIATION\n";
			#print " Adding this for update: $PERSON_ID,$DMA,$ADDRESS_ID,$STATE_ABBREVIATION\n";
			++$RECORDS_TO_UPDATE;
		}
	}
	#print "\n";
}
# And for neatness sake we close all our file handles.
close(SUBSCRIBER_LISTING);
close(ADDRESS_WITH_DMA);
print "\n\n";

# And here is where we bring it all together and do an update

# Kill our DB connection to open a new one
# Have to figure out how to finish the connection before disconnecting appearently.
#$DBH2->disconnect() or warn "Disconnection failed: $DBI::errstr\n";

$OPTIONS{db_hostname} = "mmw";          # 10.131.125.191

if (!($DBH2 = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}","$OPTIONS{db_username}","$OPTIONS{mysql_password}"))) {
    $FATAL_ERROR=1;
    $ERROR_INFO.= "DB connect error! $DBI::errstr";
    return 1;
}

# Re-open our file handle
open(STATE_UPDATE_LIST, "/tmp/address_n_dma.txt");

while(<STATE_UPDATE_LIST>) {
	chomp;
# Validate our input.  It should be clean, but why be sloppy now?
	if(/\d\d+,\d\d+,\d\d+,\w\w/) {
# Parse data by splitting on commas
		($PERSON_ID,$DMA,$ADDRESS_ID,$STATE_ABBREVIATION) = split(/,/);
		#print "My person_id is $PERSON_ID, I have address_id $ADDRESS_ID, and I belong to this dma: $DMA\n";
	} else {
		print "rejecting $_ as invalid. Something must be corrupted\n";
		++$INVALID_PERSON_ID_OR_DMA;
		next;
	}
# Update those records
	$STH = $DBH->prepare($PEOPLE_ADDRESSEES_UPDATE);
	$STH->execute($STATE_ABBREVIATION,$ADDRESS_ID) or die "Couldn't execute statement: " . $STH->errstr;
	++$UPDATED_RECORDS;
}
close(STATE_UPDATE_LIST);
# Have to figure out how to finish the connection before disconnecting appearently.
#$DBH2->disconnect() or warn "Disconnection failed: $DBI::errstr\n";


# End with some stats
print "\n";
print "Total subscribers processed: $TOTAL_ACTIVE_SUBSCRIBERS\n";
print "Total with an invalid person_id or dma:  $INVALID_PERSON_ID_OR_DMA\n";
print "Invalid data in address_id field: $INVALID_ADDRESS_ID\n";
print "NULL address ID encountered: $NULL_ADDRESS_ID\n";
print "No address IDs encountered: $NO_ADDRESS_ID\n";
print "No state_or_postal code available: $NULL_STATE_FROM_DMA\n";
print "Records that should already be correct: $CORRECT_STATE_CODE\n";
print "Records we should be able to update (See /tmp/address_n_dma.txt): $RECORDS_TO_UPDATE\n";
print "Records we were able to update: $UPDATED_RECORDS\n";
