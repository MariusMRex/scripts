#!/usr/bin/perl

use strict;
use warnings;

binmode STDOUT, ":utf8";
use utf8;
 
use JSON;

# Script to convert user data bags from chef into LDAP records.
# Marius 2016-02-03 v 1.0

# Variables for LDIF
my $FILE = $ARGV[0];
my $USERNAME;
my $FULL_NAME;
my $FIRST_NAME;
my $LAST_NAME;
my $UID_NUM;
my $GID_NUM;
my $HOME_DIR;
my $EMAIL;
my $SHA_PASSWD;
my $SHELL;
my @GROUPS;
my $GROUP;
# Variables for data processing
my $OUTPUT_FILE = "users.ldif";
my $JSON_DATA;
my $JSON_FH;
my $DATA;
my $LINE;
my $LDAP_ADMIN = '0'		# No one is an LDAP admin by default
my $COUNTER = '0';
my $COUNTER_LIMIT = '10';
my @GID_LIST;
my %GROUP_MAP = (
	"sysadmin","2300",
	"platformadmin","2302",
	"developer","2310",
	"qa","2311",
	"servicedesk","2312",
);

# If we do not get a text file as an augment, fail with a helpful message
unless($ARGV[0]) {
	print "This script needs a file as an augment.  If there is nothing to read in, there is nothing to read out.  Exiting.\n";
	exit 1;
}
# Import the json data.  The script will bomb if the json data is invalid.  Can I make that more graceful with an error message?
{
	local $/; 	#Enable 'slurp' mode
	open($JSON_FH, "<", "$FILE");
	$JSON_DATA = <$JSON_FH>;
	close($JSON_FH);
}
$DATA = decode_json($JSON_DATA);

#print "Boss' hobbies: " .
#      $data->{'boss'}->{'Hobbies'}->[0] . "n";

# Populate our variables
$USERNAME = $DATA->{'id'};
$FULL_NAME = $DATA->{'comment'};
($FIRST_NAME,$LAST_NAME) = split(/\s/,$FULL_NAME);
$UID_NUM = $DATA->{'uid'};

# Groups and GIDs can be a bit tricky
while($COUNTER <= $COUNTER_LIMIT) {
	print "Counter at: $COUNTER\n";
	if($DATA->{'groups'}->[$COUNTER]) {
		if($DATA->{'groups'}->[$COUNTER] =~ /[a-zA-Z]*/) {
			$GROUP = $DATA->{'groups'}->[$COUNTER];
			print "Found GROUP: $GROUP\n";
			push(@GROUPS,$GROUP);
			++$COUNTER;
		} else {
			print "Not a group name? -> $DATA->{'groups'}->[$COUNTER]\n";
			++$COUNTER;
		}
	} else {
		++$COUNTER;
	}
}
foreach $GROUP(@GROUPS) {
	if($GROUP =~ /[a-zA-Z]*/) {
		#Sysadmins are all LDAP admins
		if($GROUP eq "sysadmin") {
			$LDAP_ADMIN = '1';
		}
		$GID_NUM = $GROUP_MAP{$GROUP};
		print "Found GID: $GID_NUM\n";
		push(@GID_LIST,$GID_NUM);
	}
}
	
$HOME_DIR = "/home/$USERNAME";
$EMAIL = $DATA->{'email'};
$SHA_PASSWD  = $DATA->{'htpasswd'};
$SHELL = $DATA->{'shell'};

# Print out my results
open(LDIF, ">$OUTPUT_FILE");
print LDIF << "EOF";
# $FULL_NAME, People, uk, venda
dn: cn=$FULL_NAME,People,uk,venda
changetype: add
givenName: $FIRST_NAME
sn: $LAST_NAME
cn: $FULL_NAME
uid: $USERNAME
uidNumber: $UID_NUM
gidNumber: $GID_LIST[0]
homeDirectory: $HOME_DIR
loginShell: $SHELL
mail: $EMAIL
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
objectClass: user
objectClass: securityPrincipal
userPrincipalName: $EMAIL
sAMAccountName: $USERNAME
EOF

close(LDIF);
