#!/usr/bin/perl

use strict;
use warnings;
use DBI;

# Write out a proftp password file by grabbing data from the VAP
# Postgresql DB.
# Marius Rex 2013-06-11

my $DB_NAME = "vap";
my $DB_HOST = "10.0.0.149";
my $DB_USERNAME = 'vap';
my $DB_PASSWORD = "[Redacted]";
my @PW_DATA;					# Array to hold query result
my $SITE_ENTPRS;				# site.entprs
my $SITE_BSREF;					# site.bsref
my $SITE_INTGREF;				# site.intgref
my $SITE_ENV_ID;				# site.env_id
#my $FTP_ROOT; 					# Available in ft_server.cust_root, but not reliable. 
my $FTP_ROOT = "/mnt/web";
my $PASSWD_FILE = "passwd";
my $FILE_UID = 'root';
my $FILE_GID = 'root';

# passwd file is standard /etc/passwd format: USERNAME:CRYPTEDPASSWORD:UID:GID:GECOS:HOMEDIR:SHELL
my $CLIENT_USERNAME;				# Grab from ftp_account.username
my $CLIENT_PASSWD;				# Grab from ftp_account.cryptpw
my $UID = '48';					# Apache userID
my $GID = '48';					# Apache groupID
my $GECOS = '';					# default to empty
my $FTP_HOMEDIR;				# Grab from ftp_template.home_path 
my $FTP_SHELL = '/bin/false';			# Default to not allow login

# I cannot find where env_id is defined in the database, but a quick look at the entprs names yields
# 1 - WT
# 2 - test
# 6 - QA
# 7 - UAT/CustQA
# 10 - SC9
my $CHEF_ENVIRONMENT = "uat";
if($CHEF_ENVIRONMENT eq 'wt') {
	$SITE_ENV_ID = '1';
} elsif($CHEF_ENVIRONMENT eq 'sc9') {
	$SITE_ENV_ID = '10';
} elsif($CHEF_ENVIRONMENT eq 'uat') {
	$SITE_ENV_ID = '7';
} else {
	# Fall back for testing/dev environments
	$SITE_ENV_ID = '1';
}

my $dbh = DBI->connect("dbi:Pg:dbname=$DB_NAME;host=$DB_HOST", $DB_USERNAME, $DB_PASSWORD, {AutoCommit => 0})
        or die ('Cannot connect to DB');

# Create the passwd file ahead of time.
open(PASSWD, ">$PASSWD_FILE");
chown $FILE_UID, $FILE_GID, $PASSWD_FILE;
chmod "644", $PASSWD_FILE;

# execute SELECT query
my $sth = $dbh->prepare("SELECT fa.username, fa.cryptpw, ft.home_path, s.entprs, s.bsref, s.env_id, fa.intgref FROM ftp_account AS fa LEFT JOIN ftp_template AS ft ON fa.template_id = ft.id LEFT JOIN site AS s ON fa.site_id = s.id WHERE s.env_id = ?");
$sth->execute($SITE_ENV_ID);

while (@PW_DATA = $sth->fetchrow_array()) {
	$CLIENT_USERNAME = $PW_DATA[0];
	$CLIENT_PASSWD = $PW_DATA[1];
	$FTP_HOMEDIR = $PW_DATA[2];
	$SITE_ENTPRS = $PW_DATA[3];
	$SITE_BSREF = $PW_DATA[4];
	$SITE_INTGREF = $PW_DATA[5];
# $FTP_HOMEDIR may contain macros, so assuming it is defined, we need to process it
	if($FTP_HOMEDIR) {
		$FTP_HOMEDIR =~ s/\$ENTERPRISE/$SITE_ENTPRS/g;
		$FTP_HOMEDIR =~ s/\$BSREF/$SITE_BSREF/g;
		$FTP_HOMEDIR =~ s/\$INTGREF/$SITE_INTGREF/g;
		$FTP_HOMEDIR =~ s/\$CUSTROOT/$FTP_ROOT/g;
	} else {
		# if $FTP_HOMEDIR is not actually defined, lets put in a stand_in entry
		$FTP_HOMEDIR = "$FTP_ROOT/$SITE_ENTPRS/ftp/pub";
	}
# Save our results
	print PASSWD "$CLIENT_USERNAME:$CLIENT_PASSWD:$UID:$GID:$GECOS:$FTP_HOMEDIR:$FTP_SHELL\n";
}

# clean up
close(PASSWD);
$dbh->disconnect();
