#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## This script needs to take in a csv list of actions
## so it can be re-added to the master actions tabel at AWS
## so everyone can be back in sync.  It seems a rogue script was writing to 
## actions.  We want to delete the data that was added to get mysql replication running
## so we will save that data, get replication runnng, and then re-insert into the 
## Master DB.
## Marius 2012-04-23

my $dbh;                                	# Generic DB Handle
my $sth;
my $HOME = "/home/mking";
my %OPTIONS;
$OPTIONS{db_name} = "st";
#$OPTIONS{db_hostname} = "db4";          # 10.131.125.94
$OPTIONS{db_hostname} = "stsite-db";          # For wring to the master stsite DB
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
my $FATAL_ERROR;
my $ERROR_INFO;

my $INPUT_FILE = "actions.csv";

#mysql> DESC actions;
#+------------------------+------------------+------+-----+---------+----------------+
#| Field                  | Type             | Null | Key | Default | Extra          |
#+------------------------+------------------+------+-----+---------+----------------+
#| id                     | int(10) unsigned | NO   | PRI | NULL    | auto_increment | 
#| visit_id               | int(10) unsigned | YES  |     | NULL    |                | 
#| action_type_id         | int(10) unsigned | YES  |     | NULL    |                | 
#| created                | datetime         | YES  | MUL | NULL    |                | 
#| subscription_source_id | int(11)          | YES  |     | NULL    |                | 
#| subscriber_type_id     | int(11)          | YES  |     | NULL    |                | 
#| person_id              | int(11)          | YES  | MUL | NULL    |                | 
#+------------------------+------------------+------+-----+---------+----------------+
# INSERT INTO `actions` (`action_type_id`, `created`, `person_id`, `subscriber_type_id`, `subscription_source_id`, `visit_id`) VALUES (10, '2012-04-23 02:02:35', 15790174, NULL, 1, NULL)'
# 17858318,NULL,2,2012-04-22 22:02:27,8,NULL,15576512

# Data fields I will need defined.
my $A_ID;
my $A_VISIT_ID;
my $A_ACTION_TYPE_ID;
my $A_CREATED;
my $A_SUBSCRIBER_SOURCE_ID;
my $A_SUBSCRIBER_TYPE_ID;
my $A_PERSON_ID;

# MYSQL queries and Updates.
my $ACTIONS_TABLE_UPDATE = "INSERT INTO actions (id, visit_id, action_type_id, created, subscription_source_id, subscriber_type_id, person_id) VALUES (NULL, NULL, ?, ?, ?, NULL, ?)";

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

print "Grabbing $INPUT_FILE and reading it in.\n";
open(INPUT_FILE, "$INPUT_FILE");
while(<INPUT_FILE>) {
	chomp();
	($A_ID, $A_VISIT_ID, $A_ACTION_TYPE_ID, $A_CREATED, $A_SUBSCRIBER_SOURCE_ID, $A_SUBSCRIBER_TYPE_ID, $A_PERSON_ID) = split(/,/);
	#print "INSERT INTO 'actions' ('id', 'visit_id', 'action_type_id', 'created', 'subscription_source_id', 'subscriber_type_id', 'person_id') VALUES (NULL, $A_VISIT_ID, $A_ACTION_TYPE_ID, $A_CREATED, $A_SUBSCRIBER_SOURCE_ID, $A_SUBSCRIBER_TYPE_ID, $A_PERSON_ID)\;\n";
	print "INSERT INTO actions (id, visit_id, action_type_id, created, subscription_source_id, subscriber_type_id, person_id) VALUES (NULL, $A_VISIT_ID, $A_ACTION_TYPE_ID, '$A_CREATED', $A_SUBSCRIBER_SOURCE_ID, $A_SUBSCRIBER_TYPE_ID, $A_PERSON_ID)\;\n";
	$sth = $dbh->prepare($ACTIONS_TABLE_UPDATE);
	$sth->execute($A_ACTION_TYPE_ID,$A_CREATED,$A_SUBSCRIBER_SOURCE_ID,$A_PERSON_ID) or die "Couldn't execute statement: " . $sth->errstr;
	sleep 1;
}
close(INPUT_FILE);

# Finally close out our DB connections
$sth->finish();
$dbh->disconnect();
