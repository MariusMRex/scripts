#!/usr/bin/perl

use warnings;
use strict;

# Build user record for LDAP through questions and write out in LDIF form so it can be imported.
# Since some Venda applications still retain some legacy AD attributes, our user records are a bit 'special.'

my $USERNAME;
my $FULL_NAME;
my $FIRST_NAME;
my $LAST_NAME;
my $UID_NUM;
my $GID_NUM;
my $HOME_DIR;
my $EMAIL;
my $PASSWD;
my $SHELL = "/bin/bash";
my $GROUP;

my $OUTPUT_FILE;
my $GROUP_SELECT;
my $EMAIL_SELECT;
my $SYNC;
my $SYNC_SCRIPT = "/home/marius/modify_ldap.pl";
my $LDAP_ADMIN = '0';
my $PASSWORD_POLICY_REGEX = '\w{3,}';
my %GROUP_MAP = (
        "sysadmin","2300",
        "platformadmin","2302",
        "developer","2310",
        "qa","2311",
        "servicedesk","2312",
);

print "First and last name of new user: ";
chomp($FULL_NAME = <STDIN>);
until($FULL_NAME =~ /^[a-zA-Z\-]+\s[a-zA-Z\-]+$/) {
	print "I could not parse that.  Your answer should be in the form similar to: Chuck Norris\n";
	print "First and last name of new user: ";
	chomp($FULL_NAME = <STDIN>);
}
($FIRST_NAME,$LAST_NAME) = split(/\s/,$FULL_NAME);

print "Username: ";
chomp($USERNAME = <STDIN>);
until($USERNAME =~ /^[a-z]+$/) {
	print "That does not seem like a valid user name. User names should be alphabetical, and all in lower case.  Example: cnorris\n";
	print "Username: ";
	chomp($USERNAME = <STDIN>);
}

print "Is the new user's email address $USERNAME\@netsuite.com? (Y/N): ";
chomp($EMAIL_SELECT = <STDIN>);
until($EMAIL_SELECT =~ /^[YyNn]$/) {
	print "Sorry. Please try again.  Is the new user's email address $USERNAME\@netsuite.com? (Y/N): ";
	chomp($EMAIL_SELECT = <STDIN>);
}
if($EMAIL_SELECT =~ /[Yy]/) {
	$EMAIL = "$USERNAME\@netsuite.com";
} elsif($EMAIL_SELECT =~ /[Nn]/) {
	print "Please enter the correct email address: ";
	$EMAIL =  <STDIN>;
	chomp($EMAIL);
}

print "User ID number: ";
chomp($UID_NUM = <STDIN>);
until($UID_NUM =~ /^\d+$/) {
	print "Apologies, that does not look like a UID number to me.  Please try again.  Typical range of UIDs is 1000-2000.\n";
	print "User ID number: ";
	chomp($UID_NUM = <STDIN>);
}

print "Choose a primary group for the user:\n";
print "1. sysadmin\n2. platformadmin\n3. developer\n4. qa\n5. servicedesk\n: ";
chomp($GROUP_SELECT = <STDIN>);
until($GROUP_SELECT =~ /^[1-5]$/) {
	print "Sorry, I do not recognize that group number. Please enter a number from 1-5.\n";
	print "1. sysadmin\n2. platformadmin\n3. developer\n4. qa\n5. servicedesk\n: ";
	chomp($GROUP_SELECT = <STDIN>);
}
if($GROUP_SELECT == '1') {
	$GROUP = 'sysadmin';
	$LDAP_ADMIN = '1';
} elsif($GROUP_SELECT == '2') {
        $GROUP = 'platformadmin';
}elsif($GROUP_SELECT == '3') {
        $GROUP = 'developer';
}elsif($GROUP_SELECT == '4') {
        $GROUP = 'qa';
}elsif($GROUP_SELECT == '5') {
        $GROUP = 'servicedesk';
}
print "Additional groups can be added via the phpldapadmin interface later on.\n";
$GID_NUM = $GROUP_MAP{$GROUP};

print "Please provide a password for the new user (Password will no echo to terminal)\n";
system('/bin/stty', '-echo');  # Disable echoing
chomp($PASSWD = <STDIN>);
until($PASSWD =~ /$PASSWORD_POLICY_REGEX/) {
	print "That does not seem to be a valid password, try something more complex.\n";
	print "Please provide a password for the new user:\n";
	chomp($PASSWD = <STDIN>);
}
system('/bin/stty', 'echo');   # Turn echo back on

# From the above we can construct the rest
$HOME_DIR = "/home/$USERNAME";
$SHELL = "/bin/bash";
$OUTPUT_FILE = "$USERNAME" . ".ldif";

# Print out my results
open(LDIF, ">$OUTPUT_FILE");
print LDIF << "EOF";
# cn=$FULL_NAME,ou=People,dc=uk,dc=venda
dn: cn=$FULL_NAME,ou=People,dc=uk,dc=venda
changetype: add
givenName: $FIRST_NAME
sn: $LAST_NAME
cn: $FULL_NAME
uid: $USERNAME
uidNumber: $UID_NUM
gidNumber: $GID_NUM
homeDirectory: $HOME_DIR
loginShell: $SHELL
mail: $EMAIL
userPassword: $PASSWD
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: top
objectClass: user
objectClass: securityPrincipal
userPrincipalName: $EMAIL
sAMAccountName: $USERNAME

dn: cn=$GROUP,ou=groups,dc=uk,dc=venda
changetype: modify
add: memberUid
memberUid: $USERNAME
EOF

close(LDIF);

# If we are an LDAP admin, add to that group as well.
if($LDAP_ADMIN == '1') {
	open(LDIF, ">>$OUTPUT_FILE");
	print LDIF << "EOF";

# Add an LDAP administrator
dn: cn=Administrators,dc=uk,dc=venda
changetype: modify
add: member
member: cn=$FULL_NAME,ou=People,dc=uk,dc=venda
EOF
}

close(LDIF);

print "Output file \'$OUTPUT_FILE\' sucessfully created.  Import into OpenLDAP now? (Y/N)\n";
chomp($SYNC = <STDIN>);
until($SYNC =~ /^[YyNn]$/) {
        print "Sorry. Please try again. Import into OpenLDAP now? (Y/N): ";
	chomp($SYNC = <STDIN>);
}
if($SYNC =~ /[Yy]/) {
	system("$SYNC_SCRIPT $OUTPUT_FILE");
} elsif($SYNC =~ /[Nn]/) {
	print "Ok.  The new LDIF file can be imported via \"$SYNC_SCRIPT $OUTPUT_FILE\" or a normal ldapmodify command later on.\n";
}
