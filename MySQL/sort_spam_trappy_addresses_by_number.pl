#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## Looking for spam traps amoung our subscribers
##
## Another script in the series that brought us such hits as 
## sort_subscribers_by_interaction.pl and sort_subscribers_by_interaction_focus_2010_activity.pl
## 
## Thsi one may be simplier.  I have a database table st.possible_spam_traps_2011_11_04
## We have whittled down to possible_spam_traps_2011_11_04 where 99.75% of our spam traps
## seem to be located.  I am just going to grab the addresses and sort them in groups
## of 10,000 as there are only 14,6580 addresses left
##
## 11/13/2011 - Break up the 10,000 mailer groups into smaller groups
## but same numeric sort.  Doing grouyps of 670 on groups fro 11/4/2011 sort

my $dbh;                                	# Generic DB Handle
my $sth;
my $HOME = "/home/mking";
my $MAIL_SOURCE_DIR = "/home/mking/marii_bin/mailfiles/numeric_sort_2011_11_04"; # Possible Spam trap pool
#my $MAIL_SOURCE_LIST = "$MAIL_SOURCE_DIR/mailer1.txt"; # Mailed 11/13/2011
#my $MAIL_SOURCE_LIST = "$MAIL_SOURCE_DIR/mailer2.txt"; # Mailed 11/20/2011
#my $MAIL_SOURCE_LIST = "$MAIL_SOURCE_DIR/mailer3.txt"; # Mailed 12/01/2011
#my $MAIL_SOURCE_LIST = "$MAIL_SOURCE_DIR/mailer4.txt"; # Mailed 12/01/2011
#my $MAIL_SOURCE_LIST = "$MAIL_SOURCE_DIR/mailer5.txt"; # Mailed 12/13/2011
#my $MAIL_SOURCE_LIST = "$MAIL_SOURCE_DIR/mailer6.txt"; # Mailed 12/16/2011
#my $MAIL_SOURCE_LIST = "$MAIL_SOURCE_DIR/mailer7.txt"; # Mailed 12/22/2011
#my $MAIL_SOURCE_LIST = "$MAIL_SOURCE_DIR/mailer8.txt"; # Mailed 12/30/2011
#my $MAIL_SOURCE_LIST = "$MAIL_SOURCE_DIR/mailer9.txt"; # Mailed 12/31/2011
#my $MAIL_SOURCE_LIST = "$MAIL_SOURCE_DIR/mailer10.txt"; # Mailed 01/03/2012
#my $MAIL_SOURCE_LIST = "$MAIL_SOURCE_DIR/mailer11.txt"; # Mailed 01/13/2012
my $MAIL_SOURCE_LIST = "$MAIL_SOURCE_DIR/mailer12.txt"; # Mailed 01/23/2012
my $NEW_MAIL_DIR = "/home/mking/marii_bin/mailfiles/numeric_sort_2012_01_23";
my %OPTIONS;
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "db4";          # 10.131.125.94
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
my $FATAL_ERROR;
my $ERROR_INFO;

my $EMAIL;
my $PERSON_ID;
my @PEOPLE_LIST;
my @POSSIBLE_SPAM_TRAP_LIST;
my @MAILING_LIST;
my $SUBSCRIBER;
my $TOTAL_POSSIBLY_UNCLEAN_SUBSCRIBERS = "0";
my $TOTAL_ACTIVE_SUBSCRIBERS = "0";

## MYSQL queries and Updates.
my $SUBSCRIBER_QUERY = "SELECT email FROM possible_spam_traps_2011_11_04";   
my $PERSON_ID_QUERY = "SELECT id FROM people WHERE email = ?";

# Lets create a directory, to stick mail files into, if it does not already exist
unless(-d "$NEW_MAIL_DIR") {
	print "Making $NEW_MAIL_DIR for storage of mail files.\n";
	mkdir("$NEW_MAIL_DIR",0777) || die "Cannot mkdir $NEW_MAIL_DIR: $!";
}

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

# O.K.  Lets get a list of users
#print "Lets grab the list of people from the spam trap profile pool\n";
#$sth = $dbh->prepare($SUBSCRIBER_QUERY);
#$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
#while (@PEOPLE_LIST = $sth->fetchrow_array()) {
#	$EMAIL = $PEOPLE_LIST[0];
#	push(@POSSIBLE_SPAM_TRAP_LIST,$EMAIL);
#	++$TOTAL_POSSIBLY_UNCLEAN_SUBSCRIBERS;
#}
# Use a flat file instead
open(MASTER_LIST, "$MAIL_SOURCE_LIST");
print "Opening up $MAIL_SOURCE_LIST for processing.\n";
while(<MASTER_LIST>) {
	($EMAIL,$PERSON_ID) = split(/\t/);
	#$EMAIL = $_;
	chomp($EMAIL);
	push(@POSSIBLE_SPAM_TRAP_LIST,$EMAIL);
	++$TOTAL_POSSIBLY_UNCLEAN_SUBSCRIBERS;
}
print "Total Active Possibly unclean subscribers found: $TOTAL_POSSIBLY_UNCLEAN_SUBSCRIBERS\n";
sleep 2;

# Lets open my mail files
open(MASTER, ">$NEW_MAIL_DIR/master.txt"); 
open(MAILER1, ">$NEW_MAIL_DIR/mailer1.txt");
open(MAILER2, ">$NEW_MAIL_DIR/mailer2.txt");
open(MAILER3, ">$NEW_MAIL_DIR/mailer3.txt");
open(MAILER4, ">$NEW_MAIL_DIR/mailer4.txt");
open(MAILER5, ">$NEW_MAIL_DIR/mailer5.txt");
open(MAILER6, ">$NEW_MAIL_DIR/mailer6.txt");
open(MAILER7, ">$NEW_MAIL_DIR/mailer7.txt");
open(MAILER8, ">$NEW_MAIL_DIR/mailer8.txt");
open(MAILER9, ">$NEW_MAIL_DIR/mailer9.txt");
open(MAILER10, ">$NEW_MAIL_DIR/mailer10.txt");
open(MAILER11, ">$NEW_MAIL_DIR/mailer11.txt");
open(MAILER12, ">$NEW_MAIL_DIR/mailer12.txt");
open(MAILER13, ">$NEW_MAIL_DIR/mailer13.txt");
open(MAILER14, ">$NEW_MAIL_DIR/mailer14.txt");
open(MAILER15, ">$NEW_MAIL_DIR/mailer15.txt");
open(UNLOVED, ">$NEW_MAIL_DIR/lost_sheep.txt");

# Lets grab the person_ids we need and make out lists
print "getting person_id information.\n";
print "Sorting to mailer groups.\n";
foreach $EMAIL(@POSSIBLE_SPAM_TRAP_LIST) {
	#sleep 1;
	++$TOTAL_ACTIVE_SUBSCRIBERS;
	#print "Looking up $EMAIL at number $TOTAL_ACTIVE_SUBSCRIBERS\n";
	$sth = $dbh->prepare($PERSON_ID_QUERY);
	$sth->execute($EMAIL) or die "Couldn't execute statement: " . $sth->errstr;
	$PERSON_ID = $sth->fetchrow();
	#print "Processing $EMAIL $PERSON_ID\n";
	#sleep 1;
# Every email address should go in master.txt, as other mailing scripts depend on it
	print MASTER "$EMAIL\t$PERSON_ID\n";
# Now we sort by groups of 10,000
	#if($TOTAL_ACTIVE_SUBSCRIBERS <= "10000") {
	if($TOTAL_ACTIVE_SUBSCRIBERS <= "670") {
		print MAILER1 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "10000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "20000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "670") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "1340")) {
		print MAILER2 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "20000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "30000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "1340") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "2010")) {
		print MAILER3 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "30000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "40000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "2010") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "2680")) {
		print MAILER4 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "40000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "50000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "2680") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "3350")) {
		print MAILER5 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "50000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "60000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "3350") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "4020")) {
		print MAILER6 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "60000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "70000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "4020") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "4690")) {
		print MAILER7 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "70000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "80000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "4690") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "5360")) {
		print MAILER8 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "80000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "90000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "5360") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "6030")) {
		print MAILER9 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "90000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "100000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "6030") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "6700")) {
		print MAILER10 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "100000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "110000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "6700") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "7370")) {
		print MAILER11 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "110000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "120000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "7370") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "8040")) {
		print MAILER12 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "120000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "130000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "8040") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "8710")) {
		print MAILER13 "$EMAIL\t$PERSON_ID\n";
	}
	#if(($TOTAL_ACTIVE_SUBSCRIBERS > "130000") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "140000")) {
	if(($TOTAL_ACTIVE_SUBSCRIBERS > "8710") && ($TOTAL_ACTIVE_SUBSCRIBERS <= "9380")) {
		print MAILER14 "$EMAIL\t$PERSON_ID\n";
	}
# Else put it in mailer15
	#if($TOTAL_ACTIVE_SUBSCRIBERS > "140000") {
	if($TOTAL_ACTIVE_SUBSCRIBERS > "9380") {
		print MAILER15 "$EMAIL\t$PERSON_ID\n";
	}
}
print "Total email addresses sorted: $TOTAL_ACTIVE_SUBSCRIBERS\n";

# Close out open files:
close(MASTER);
close(MAILER1);
close(MAILER2);
close(MAILER3);
close(MAILER4);
close(MAILER5);
close(MAILER6);
close(MAILER7);
close(MAILER8);
close(MAILER9);
close(MAILER10);
close(MAILER11);
close(MAILER12);
close(MAILER13);
close(MAILER14);
close(MAILER15);
close(UNLOVED);

# Finally close out our DB connections
$sth->finish();
$dbh->disconnect();
