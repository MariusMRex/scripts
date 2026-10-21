#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## This script...
##
## Marius 2011-10-25


my $dbh;                                	# Generic DB Handle
my $sth;
#my $HOME = "/home/mking";
my $HOME = "/home/marius";
my %OPTIONS;
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "db4";          # 10.131.125.94
#$OPTIONS{db_hostname} = "stsite-db";          # For wring to the master stsite DB
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";

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

print "Grabbing password file\n";
# Open the file with the mysql password
open (FH, "$OPTIONS{db_password_file}");
flock FH,2;
my $MYSQL_PASSWORD=<FH>;
close FH;
chomp $MYSQL_PASSWORD;

print "Initiating database connection.\n";
# if our database handle cannot connect, spit out an error string and die
$dbh = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}",$OPTIONS{db_username},$MYSQL_PASSWORD, {RaiseError => 1});

#print "Doing Stuffn";
#foreach $SUBSCRIBER(@SUBSCRIBER_LIST) {
	#print "Subscriber is $SUBSCRIBER\n";
#	$sth = $dbh->prepare($P1_CLICK_QUERY);
#	$sth->execute($SUBSCRIBER) or die "Couldn't execute statement: " . $sth->errstr;
#	$EMAIL = $sth->fetchrow();
#	if($sth->rows == 0) {
		#print "Pushing $SUBSCRIBER to next bucket\n";
#		push(@NO_CLICK_P1,$SUBSCRIBER);
#	} else {
#		print P1 "$EMAIL\t$SUBSCRIBER\n";
#		++$P1_CLICK_COUNT;
		#print "Putting $SUBSCRIBER in current bucket\n";
#	}
#}

#$sth = $dbh->prepare($UNSUBSCRIBE_COMPLAINTS_QUERY);
#$sth->execute($S_CREATED_START,$S_MODIFIED_END) or die "Couldn't execute statement: " . $sth->errstr;
#while (@SUBSCRIBER_DATA = $sth->fetchrow_array()) {
#		$UNSUBSCRIBER_DATE = $SUBSCRIBER_DATA[0];
#			$UNSUBSCRIBER_COUNT = $SUBSCRIBER_DATA[1];
#				print UNSUBS_COMPLAINTS "$UNSUBSCRIBER_DATE,$UNSUBSCRIBER_COUNT\n";
#}
#close(UNSUBS_COMPLAINTS);

## Drop the table if its already there
#$dbh->do("DROP TABLE IF EXISTS $CONFIG{'table'}");
#
#
# $CONFIG{'table'} = 'tmp_mailer_gen_extra';
## Create the table if it doesn't exist
# $dbh->do("CREATE TABLE IF NOT EXISTS `$CONFIG{'table'}` (
#                 `email` VARCHAR(200),
#                 PRIMARY KEY (`email`))
#        ");


# Finally close out our DB connections
$sth->finish();
$dbh->disconnect();
