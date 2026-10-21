#!/usr/local/bin/perl

# This script was written for Trac 

use strict;
use warnings;

require DBD::mysql;

my $DBH;								# Generic DB Handle
my $COUNT = 0;
my $HOME = "/home/mking";
my %OPTIONS;
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "db4";			# 10.131.125.94
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
$OPTIONS{p_table} = "people";
$OPTIONS{pa_table} = "people_addresses";
$OPTIONS{rso_table} = "reader_service_optins";
my $FATAL_ERROR;
my $ERROR_INFO;

# PreDeclare our fields from the form.  Pre-populate when we can 
my $START_LINE = "RSC_Domestic";
my $PREFIX = " ";
my $FIRST_NAME;
my $LAST_NAME;
my $SUFFIX = " ";
my $COMPANY_NAME = " "; 
my $ADDRESS;
my $ADDRESS2;
my $CITY;
my $STATE;
my $ZIP;
my $ZIP4 = " ";
my $COUNTRY = "USA";
my $AD_CODE = "5ESH11";
#my $MEDIUM_CODE = "5";  Elle told me '5' but the Docs suggest it might be '3'
my $MEDIUM_CODE = "3";  
#my $SOURCE_CODE = "5ESH11";
my $SOURCE_CODE = "rscfhstm01";
my $QUANTITY = "1";
my $PACKAGE_CODE = "1";
my $DATETIME;
my $NEWLINE = "\n";
my $PADDED;

# Length of associated fields
# These are mandiated and must be enforced.
my $PREFIX_LEN = "10";
my $FIRST_NAME_LEN = "15";
my $LAST_NAME_LEN = "20";
my $SUFFIX_LEN = "10";
my $COMPANY_NAME_LEN = "35";
my $ADDRESS_LEN = "35";
my $ADDRESS2_LEN = "35";
my $CITY_LEN = "30";
my $STATE_LEN = "2";
my $ZIP_LEN = "5";
my $ZIP4_LEN = "4";
my $COUNTRY_LEN = "30";
my $AD_CODE_LEN = "6";
my $MEDIUM_CODE_LEN = "2";
my $SOURCE_CODE_LEN = "10";
my $QUANTITY_LEN = "2";
my $PACKAGE_CODE_LEN = "3";
my $DATETIME_LEN = "20";

my $QUERY = "SELECT p.first_name, p.last_name, pa.address, pa.address_2, pa.city, pa.state_or_territory, pa.postal_code, rso.created FROM reader_service_optins AS rso LEFT JOIN people AS p ON rso.person_id = p.id LEFT JOIN people_addresses AS pa ON p.address_id = pa.id WHERE reader_service_partner_id = 514 AND rso.created BETWEEN '2011-05-29 00:00:00' AND '2011-06-04 23:59:59' ORDER BY rso.created";

# Here is the structure of the various tables
# mysql> DESC people;
#+-----------------------+---------------------+------+-----+---------+----------------+
#| Field                 | Type                | Null | Key | Default | Extra          |
#+-----------------------+---------------------+------+-----+---------+----------------+
#| id                    | int(10) unsigned    | NO   | PRI | NULL    | auto_increment | 
#| visitor_id            | int(10) unsigned    | YES  | MUL | NULL    |                | 
#| address_id            | int(10) unsigned    | YES  | MUL | NULL    |                | 
#| first_name            | varchar(125)        | YES  |     | NULL    |                | 
#| last_name             | varchar(65)         | YES  |     | NULL    |                | 
#| email                 | varchar(100)        | NO   | MUL | NULL    |                | 
#| created               | datetime            | YES  |     | NULL    |                | 
#| modified              | datetime            | YES  |     | NULL    |                | 
#| refer_id              | int(10) unsigned    | YES  |     | NULL    |                | 
#| source                | varchar(255)        | NO   |     |         |                | 
#| is_administrator      | bit(1)              | YES  |     | NULL    |                | 
#| username              | varchar(20)         | YES  | UNI | NULL    |                | 
#| password              | varchar(40)         | YES  |     | NULL    |                | 
#| recovery_requested_at | datetime            | YES  |     | NULL    |                | 
#| registered_at         | datetime            | YES  |     | NULL    |                | 
#| confirmed_at          | datetime            | YES  |     | NULL    |                | 
#| confirmation_id       | varchar(40)         | YES  | UNI | NULL    |                | 
#| facebook_id           | bigint(20) unsigned | YES  | UNI | NULL    |                | 
#+-----------------------+---------------------+------+-----+---------+----------------+
#
# mysql> DESC people_addresses;
#+--------------------+-----------------------+------+-----+---------+----------------+
#| Field              | Type                  | Null | Key | Default | Extra          |
#+--------------------+-----------------------+------+-----+---------+----------------+
#| id                 | int(10) unsigned      | NO   | PRI | NULL    | auto_increment | 
#| address            | varchar(200)          | YES  | MUL | NULL    |                | 
#| address_2          | varchar(160)          | YES  |     | NULL    |                | 
#| city               | varchar(60)           | YES  |     | NULL    |                | 
#| state_or_territory | varchar(25)           | YES  |     | NULL    |                | 
#| postal_code        | varchar(25)           | YES  | MUL | NULL    |                | 
#| country_id         | mediumint(6) unsigned | YES  |     | NULL    |                | 
#| phone              | varchar(75)           | YES  |     | NULL    |                | 
#| fax                | varchar(25)           | YES  |     | NULL    |                | 
#| city_id            | int(11)               | YES  |     | NULL    |                | 
#| state_id           | int(11)               | YES  |     | NULL    |                | 
#| url                | varchar(80)           | YES  |     | NULL    |                | 
#+--------------------+-----------------------+------+-----+---------+----------------+
#
# mysql> DESC reader_service_optins;
#+---------------------------+------------------+------+-----+---------+----------------+
#| Field                     | Type             | Null | Key | Default | Extra          |
#+---------------------------+------------------+------+-----+---------+----------------+
#| id                        | int(11)          | NO   | PRI | NULL    | auto_increment | 
#| reader_service_partner_id | int(10) unsigned | NO   | MUL | NULL    |                | 
#| person_id                 | int(11) unsigned | NO   |     | NULL    |                | 
#| visit_id                  | int(11) unsigned | YES  |     | NULL    |                | 
#| created                   | datetime         | YES  |     | NULL    |                | 
#| modified                  | datetime         | YES  |     | NULL    |                | 
#+---------------------------+------------------+------+-----+---------+----------------+

# Fields
# Max 20 entries per discreet file.  
# Each discrete file must be suffixed with ".txt"
# First line of any file needs to be RSC_Domestic
# The numbers following are size of field in characters. Cut if too long, pad if to short
# The following characters are illegal in any field besides date: [ ] { } ; | :
# blank (Name prefix) 10
# p.first_name 15
# p.last_name  (Required) 20
# blank (Name suffix) 10
# blank (Required - Company Name) 35
# pa.address (Required) 35
# pa.address_2 35
# pa.city (Required) 30
# pa.state_or_territory (Required) 2
# pa.postal_code (Required) 5
# blank(?) (zip+4) 4
# USA (Required) 30
# (Ad Code?) (Required) 6
# 3 (Required) 2
# (source_code) (Required) 10
# 1 (Required) 2
# 1 (Required) 3
# rso.created in the format of DD/MM/YYYY\sHH:MM:SS\s (Required) 20 (already 20 by format)
# NewLine characer (Required)

# Open the file with the mysql password
open (FH, "$OPTIONS{db_password_file}");
	flock FH,2;
	$OPTIONS{mysql_password}=<FH>;
close FH;
chomp $OPTIONS{mysql_password};

# if our database handle cannot connect, spit out an error string and die
if (!($DBH = DBI->connect("DBI:mysql:database=$OPTIONS{db_name};host=$OPTIONS{db_hostname}","$OPTIONS{db_username}","$OPTIONS{mysql_password}"))) {
	$FATAL_ERROR=1;
	$ERROR_INFO.= "DB connect error! $DBI::errstr";
	return 1;
}

my $STH = $DBH->prepare($QUERY);

$STH->execute();

#open(FTP_FILE, ">/var/tmp/Texas_tourism.txt")
#print FTP_FILE "$START_LINE\n";
print "$START_LINE\n";

while (my $REF = $STH->fetchrow_hashref()) {
	open (OUTFILE, ">shermanstravel.txt");
# Probably create a subroutine here
	$PREFIX = pack("A$PREFIX_LEN",$PREFIX);
	$FIRST_NAME =  pack("A$FIRST_NAME_LEN",$REF->{'first_name'});
	$LAST_NAME =  pack("A$LAST_NAME_LEN",$REF->{'last_name'});
	$SUFFIX = pack("A$SUFFIX_LEN",$SUFFIX);
	$COMPANY_NAME = pack("A$COMPANY_NAME_LEN",$COMPANY_NAME);
	$ADDRESS =  pack("A$ADDRESS_LEN",$REF->{'address'});
	$ADDRESS2 =  pack("A$ADDRESS2_LEN",$REF->{'address_2'});
	$CITY =  pack("A$CITY_LEN",$REF->{'city'});
	$STATE =  pack("A$STATE_LEN",$REF->{'state_or_territory'});
	$ZIP =  pack("A$ZIP_LEN",$REF->{'postal_code'});
	$ZIP4 =  pack("A$ZIP4_LEN",$ZIP4);
	$COUNTRY =  pack("A$COUNTRY_LEN",$COUNTRY);
	$AD_CODE =  pack("A$AD_CODE_LEN",$AD_CODE);
	$MEDIUM_CODE =  pack("A$MEDIUM_CODE_LEN",$MEDIUM_CODE);
	$SOURCE_CODE =  pack("A$SOURCE_CODE_LEN",$SOURCE_CODE);
	$QUANTITY =  pack("A$QUANTITY_LEN",$QUANTITY);
	$PACKAGE_CODE =  pack("A$PACKAGE_CODE_LEN",$PACKAGE_CODE);
# Need to fix date format to comply with TIS standards" "DD/MM/YYYY HH:MM:SS " 
	my $MYSQL_DATETIME  = $REF->{'created'};
	if($MYSQL_DATETIME =~ /(\d\d\d\d)-(\d\d)-(\d\d)\s(\d\d:\d\d:\d\d)/) {
		my $YEAR = $1;
		my $MONTH = $2;
		my $DAY = $3;
		my $TIMESTAMP = $4;
		my $CORRECTED_DATETIME = "$DAY/$MONTH/$YEAR $TIMESTAMP";
		#chomp($CORRECTED_DATETIME);
		$DATETIME = pack("A$DATETIME_LEN",$CORRECTED_DATETIME);
	}
	#unless( -e $LAST_NAME && -e $ADDRESS &&  -e $CITY && -e $STATE && -e $ZIP && -e $COUNTRY && -e $AD_CODE && -e $MEDIUM_CODE && -e $SOURCE_CODE && -e $QUANTITY && -e $PACKAGE_CODE && -e $DATETIME) {
	#unless( -e $LAST_NAME && $ADDRESS &&  $CITY && $STATE && $ZIP && $COUNTRY && $AD_CODE && $MEDIUM_CODE && $SOURCE_CODE && $QUANTITY && $PACKAGE_CODE && $DATETIME) {
	#	print " Bad line: $PREFIX$FIRST_NAME$LAST_NAME$SUFFIX$COMPANY_NAME$ADDRESS$ADDRESS2$CITY$STATE$ZIP$ZIP4$COUNTRY$AD_CODE$MEDIUM_CODE$SOURCE_CODE$QUANTITY$PACKAGE_CODE$DATETIME$NEWLINE";
	#} else {
		print "$PREFIX$FIRST_NAME$LAST_NAME$SUFFIX$COMPANY_NAME$ADDRESS$ADDRESS2$CITY$STATE$ZIP$ZIP4$COUNTRY$AD_CODE$MEDIUM_CODE$SOURCE_CODE$QUANTITY$PACKAGE_CODE$DATETIME$NEWLINE";
	#}
}
close(OUTFILE);

# All Done?
$STH->finish();

# Disconnect from the database.
$DBH->disconnect();
