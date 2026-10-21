#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## The overarching goal:
# We have a list of 5000 hard bounces from 2012-01-(27-28)
# First we read in the list of emails, one per line
# Next we query st.people on email to get p.id
# Push to a file: print MAILFILE "$EMAIL\t$PERSON_ID\n";
# re-enable subscriptions: 
#      UPDATE subscriptions set is_unsubscribed = 0, unsubscribe_reason = NULL, modified = NOW() WHERE person_id = $PERSON_ID
# Mail mail file, in this case all in one as 5K is not a huge mail file.
# Tomorrow we look at bounce results. 
# Please specify the date range on the command line
# Run this on admin, or any NFS mounted homedir

my $HOME = "/home/mking";
my $DB_Database = "st";
my $DB_Host = "10.131.125.191";          # mmr
my $DB_Username = "webuser";
my $DB_Password = "[Redacted]";
my $FATAL_ERROR;
my $ERROR_INFO;

my $EMAIL;
my $PERSON_ID;
my $LOST_COUNT = '0';
my $FOUND_COUNT = '0';

# MYSQL queries and Updates.
my $PID_QUERY = "SELECT id FROM people WHERE email = ?";
my $RESUB_UPDATE = "UPDATE subscriptions SET is_unsubscribed = '0', unsubscribe_reason_id = NULL, modified = NOW() WHERE person_id = ?";

my $dbh=DBI->connect("DBI:mysql:host=$DB_Host;database=$DB_Database","$DB_Username", "$DB_Password", {PrintError=>0, RaiseError=>0})
	or
	die("Failed connecting to Db4 ". "(error number $DBI::err): $DBI::errstr\n"); 
my $sth;

# Source file
open(SOURCE_FILE, "just_emails_unsub_2012-01-27.txt");
# MAIL output file
open(MAIL_FILE, ">/home/mking/marii_bin/mailfiles/resub_hardbounce_for_2012_01_27.txt");

while(<SOURCE_FILE>) {
	print "Opening up source for processing.\n";
	chomp;
	$EMAIL = $_;
	print "Email: $EMAIL ";
	$sth = $dbh->prepare($PID_QUERY);
	$sth->execute($EMAIL) or die "Couldn't execute statement: " . $sth->errstr;
	unless ($sth->rows == 0) {
		$PERSON_ID = $sth->fetchrow();
		print "Person ID: $PERSON_ID\n";
		print MAIL_FILE "$EMAIL\t$PERSON_ID\n";
		$sth = $dbh->prepare($RESUB_UPDATE);
		$sth->execute($PERSON_ID) or die "Couldn't execute statement: " . $sth->errstr;
		++$FOUND_COUNT
	} else {
		print "...Cannot find person ID\n";
		++$LOST_COUNT;
	}
}
close(SOURCE_FILE);
close(MAIL_FILE);

$sth->finish();
$dbh->disconnect();

print "$FOUND_COUNT addresses updated\n";
print "$LOST_COUNT emails could not be updated.\n";

