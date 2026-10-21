#!/usr/bin/perl 

use strict;
use warnings;

require DBD::mysql;

## Kal wants me to breaks down special interest categories
## of recent subscribers (2011) by month.
## How many subscribed to each special interest category
## and how many did not subscribe to anya


##SELECT created, subscription_type_id,  COUNT(person_id) AS total FROM subscriptions WHERE created BETWEEN DATE_SUB('2011-01-01', INTERVAL 1 MONTH) AND CURDATE() GROUP BY person_id, subscription_type_id ORDER BY created;


#mysl> DEC special_interests;
#+------+--------------------------+
#| id   | name                     |
#+------+--------------------------+
#| 1241 | All-Inclusive Travel     | 
#|    8 | Beach                    | 
#|   13 | Business Travel          | 
#|    6 | Cruise                   | 
#| 1260 | Eco-Travel               | 
#|    9 | Family                   | 
#|    4 | Gambling                 | 
#|   10 | Gay and Lesbian          | 
#|    7 | Golf                     | 
#|   12 | International Travel     | 
#|    1 | Luxury                   | 
#| 1254 | naturist                 | 
#|   14 | Romance                  | 
#|   11 | Senior                   | 
#|    5 | Skiing                   | 
#| 1258 | Spas & Resorts           | 
#|    2 | Sports and Adventure     | 
#| 1199 | Travel Tips and Strategy | 
#| 1245 | USAToday                 | 
#+------+--------------------------+
#
#mysql> DESC subscriptions;
#+-----------------------+---------------------+------+-----+---------+----------------+
#| Field                 | Type                | Null | Key | Default | Extra          |
#+-----------------------+---------------------+------+-----+---------+----------------+
#| person_id             | int(10) unsigned    | NO   | MUL | 0       |                | 
#| subscription_type_id  | tinyint(3) unsigned | NO   |     | 0       |                | 
#| created               | datetime            | YES  | MUL | NULL    |                | 
#| modified              | datetime            | YES  |     | NULL    |                | 
#| is_unsubscribed       | tinyint(1)          | NO   | MUL | 0       |                | 
#| unsubscribe_reason_id | tinyint(1) unsigned | YES  |     | NULL    |                | 
#| source_id             | tinyint(3)          | NO   |     | 0       |                | 
#| id                    | int(11)             | NO   | PRI | NULL    | auto_increment | 
#| double_opt_in_confirm | char(1)             | NO   |     | 0       |                | 
#+-----------------------+---------------------+------+-----+---------+----------------+


## Marius 2011-10-05

my $DBH;                                	# Generic DB Handle
my $STH;
my $HOME = "/home/mking";
my %OPTIONS;
$OPTIONS{db_name} = "st";
$OPTIONS{db_hostname} = "db4";          # 10.131.125.94
$OPTIONS{db_username} = "webuser";
$OPTIONS{db_password_file} = "$HOME/webuser_mysql.pwd";
my $FATAL_ERROR;
my $ERROR_INFO;

my $TOTAL_SUB_MONTH;
my $TOTAL_SI_MONTH;
my $TOTAL_NO_SI_MONTH;
my $TOTAL_SI_BEACH;
my $TOTAL_SI_BUSINESS_TRAVEL;
my $TOTAL_SI_CRUISE;
my $TOTAL_SI_FAMILY;
my $TOTAL_SI_GAMBLING;
my $TOTAL_SI_GAY;
my $TOTAL_SI_GOLF;
my $TOTAL_SI_INTERNATIONAL;
my $TOTAL_SI_LUXURY;
my $TOTAL_SI_ROMANCE;
my $TOTAL_SI_SENIOR;
my $TOTAL_SI_SKIING;
my $TOTAL_SI_SPA;
my $TOTAL_SI_SPORT;
my $TOTAL_SI_TRAVEL_TIPS;
my $REPORT_DATE = `/bin/date`;

my %SPECIAL_INTERESTS = (
	"1","Luxury",
	"2","Sports and Adventure",
	"4","Gambling",
	"5","Skiing",
	"6","Cruise",
	"7","Golf",
	"8","Beach",
	"9","Family",
	"10","Gay and Lesbian",
	"11","Senior",
	"12","International Travel",
	"13","Business Travel",
	"14","Romance",
	"1199","Travel Tips and Strategy",
	"1241","All-Inclusive Travel",
	"1245","USAToday",
	"1254","naturist",
	"1258","Spas & Resorts",
	"1260","Eco-Travel", 
);

my $YEAR = "2011";
# $COUNT starts at '0' so we number our months 0-11
my %MONTH = qw(
	0	January
	1	February
	2	March
	3	April
	4	May
	5	June
	6	July
	7	August
	8 	September
	9	October
	10	November
	11	December
);

# Date ranges to divvy up subscribers, since we have so many
my $COUNT = "0";
my $BEGIN_DATE;
my @BDATE = ("2011-01-01 00:00:00","2011-02-01 00:00:00","2011-03-01 00:00:00","2011-04-01 00:00:00","2011-05-01 00:00:00","2011-06-01 00:00:00","2011-07-01 00:00:00","2011-08-01 00:00:00","2011-09-01 00:00:00","2011-10-01 00:00:00","2011-11-01 00:00:00","2011-12-01 00:00:00");
my $END_DATE;
my @EDATE = ("2011-01-31 23:59:59","2011-02-28 23:59:59","2011-03-31 23:59:59","2011-04-30 23:59:59","2011-05-31 23:59:59","2011-06-30 23:59:59","2011-07-31 23:59:59","2011-08-31 23:59:59","2008-09-30 23:59:59","2011-10-31 23:59:59","2011-11-30 23:59:59","2011-12-31 23:59:59");

# MYSQL queries and Updates.
my $TOTAL_COUNT_BY_YEAR_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ?";
my $TOTAL_SI_BY_YEAR_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND (spec_interest_travel_tips = 'Y' OR spec_interest_sport = 'Y' OR spec_interest_spa = 'Y' OR spec_interest_skiing = 'Y' OR spec_interest_senior = 'Y' OR spec_interest_luxury = 'Y' OR spec_interest_romance = 'Y' OR spec_interest_international = 'Y' OR spec_interest_golf = 'Y' OR spec_interest_gay = 'Y' OR spec_interest_gambling = 'Y' OR spec_interest_family = 'Y' OR spec_interest_cruise = 'Y' OR spec_interest_business_travel = 'Y' OR spec_interest_beach = 'Y')";
my $TOTAL_NO_SI_BY_YEAR_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND (spec_interest_travel_tips = 'N' AND spec_interest_sport = 'N' AND spec_interest_spa = 'N' AND spec_interest_skiing = 'N' AND spec_interest_senior = 'N' AND spec_interest_luxury = 'N' AND spec_interest_romance = 'N' AND  spec_interest_international = 'N' AND spec_interest_golf = 'N' AND spec_interest_gay = 'N' AND spec_interest_gambling = 'N' AND spec_interest_family = 'N' AND spec_interest_cruise = 'N' AND spec_interest_business_travel = 'N' AND spec_interest_beach = 'N')";
my $SI_BEACH_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_beach = 'Y'";
my $SI_BUSINESS_TRAVEL_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_business_travel = 'Y'";
my $SI_CRUISE_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_cruise = 'Y'";
my $SI_FAMILY_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_family = 'Y'";
my $SI_GAMBLING_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_gambling = 'Y'";
my $SI_GAY_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_gay = 'Y'";
my $SI_GOLF_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_golf = 'Y'";
my $SI_INTERNATIONAL_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_international = 'Y'";
my $SI_LUXURY_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_luxury = 'Y'";
my $SI_ROMANCE_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_romance = 'Y'";
my $SI_SENIOR_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_senior = 'Y'";
my $SI_SKIING_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_skiing = 'Y'";
my $SI_SPA_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_spa = 'Y'";
my $SI_SPORT_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_sport = 'Y'";
my $SI_TRAVEL_TIPS_QUERY = "SELECT COUNT(person_id) FROM derived_address WHERE created BETWEEN ? AND ? AND spec_interest_travel_tips = 'Y'";

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

open(SI_LIST, ">/tmp/special_interests_breakdown_$YEAR.txt");

#open(LIST, "$PERSON_ID_LIST");
#UNIQUEPID: while(<LIST>) {
#	$PERSON_ID = $_;
#	chomp($PERSON_ID);
# print "person_id is $PERSON_ID.\n";
print SI_LIST "Special Interest Report for $YEAR\n\n";
# 12 months, but teh count starts at 0 so 11 is max value
while($COUNT <= "11") {
	$BEGIN_DATE = "$BDATE[$COUNT]";
	$END_DATE = "$EDATE[$COUNT]";
	print "Query on $BEGIN_DATE to $END_DATE\n";
	print SI_LIST "$MONTH{$COUNT}\n";
# Get total Subscribers per month
	$STH = $DBH->prepare($TOTAL_COUNT_BY_YEAR_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SUB_MONTH = $STH->fetchrow();
		print SI_LIST "Total: $TOTAL_SUB_MONTH\n";
	} else {
		print SI_LIST "Found no active subscribers that subscribed in %MONTH{$COUNT} $YEAR\n";
		next;
	}
# Get total subscribers who have any Special Interests listed
	$STH = $DBH->prepare($TOTAL_SI_BY_YEAR_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_MONTH = $STH->fetchrow();
		print SI_LIST "Total with any special interests listed: $TOTAL_SI_MONTH\n";
	} else {
		print SI_LIST "Found no active subscribers that have special Interests listed in %MONTH{$COUNT} $YEAR\n";
	}
# Get total susbcribers who have no special interests listed
	$STH = $DBH->prepare($TOTAL_NO_SI_BY_YEAR_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_NO_SI_MONTH = $STH->fetchrow();
		print SI_LIST "Total with no special interests listed: $TOTAL_NO_SI_MONTH\n";
	} else {
		print SI_LIST "Found no active subscribers that have zero special Interests listed in %MONTH{$COUNT} $YEAR\n";
	}
# Special Interests Beach
	$STH = $DBH->prepare($SI_BEACH_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_BEACH = $STH->fetchrow();
		print SI_LIST "Special Interest Beach: $TOTAL_SI_BEACH\n";
	} else {
		print SI_LIST "Special Interest Beach: NA\n";
	}
# Special Interests Business Travel
	$STH = $DBH->prepare($SI_BUSINESS_TRAVEL_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_BUSINESS_TRAVEL = $STH->fetchrow();
		print SI_LIST "Special Interest Business Travel: $TOTAL_SI_BUSINESS_TRAVEL\n";
	} else {
		print SI_LIST "Special Interest Business Travel: NA\n";
	}
# Special Interests Cruise 
	$STH = $DBH->prepare($SI_CRUISE_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_CRUISE = $STH->fetchrow();
		print SI_LIST "Special Interest Cruise: $TOTAL_SI_CRUISE\n";
	} else {
		print SI_LIST "Special Interest Cruise: NA\n";
	}
# Special Interests Family
	$STH = $DBH->prepare($SI_FAMILY_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_FAMILY = $STH->fetchrow();
		print SI_LIST "Special Interest Family: $TOTAL_SI_FAMILY\n";
	} else {
		print SI_LIST "Special Interest Family: NA\n";
	}
# Special Interests Gambling
	$STH = $DBH->prepare($SI_GAMBLING_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_GAMBLING = $STH->fetchrow();
		print SI_LIST "Special Interest Gambling: $TOTAL_SI_GAMBLING\n";
	} else {
		print SI_LIST "Special Interest Gambling: NA\n";
	}
# Special Interests Gay
	$STH = $DBH->prepare($SI_GAY_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_GAY = $STH->fetchrow();
		print SI_LIST "Special Interest Gay: $TOTAL_SI_GAY\n";
	} else {
		print SI_LIST "Special Interest Gay: NA\n";
	}
# Special Interests Golf
	$STH = $DBH->prepare($SI_GOLF_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_GOLF = $STH->fetchrow();
		print SI_LIST "Special Interest Golf: $TOTAL_SI_GOLF\n";
	} else {
		print SI_LIST "Special Interest Golf: NA\n";
	}
# Special Interests International
	$STH = $DBH->prepare($SI_INTERNATIONAL_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_INTERNATIONAL = $STH->fetchrow();
		print SI_LIST "Special Interest International: $TOTAL_SI_INTERNATIONAL\n";
	} else {
		print SI_LIST "Special Interest International: NA\n";
	}
# Special Interests Luxury
	$STH = $DBH->prepare($SI_LUXURY_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_LUXURY = $STH->fetchrow();
		print SI_LIST "Special Interest Luxury: $TOTAL_SI_LUXURY\n";
	} else {
		print SI_LIST "Special Interest Luxury: NA\n";
	}
# Special Interests Romance
	$STH = $DBH->prepare($SI_ROMANCE_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_ROMANCE = $STH->fetchrow();
		print SI_LIST "Special Interest Romance: $TOTAL_SI_ROMANCE\n";
	} else {
		print SI_LIST "Special Interest Romance: NA\n";
	}
# Special Interests Senior
	$STH = $DBH->prepare($SI_SENIOR_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_SENIOR = $STH->fetchrow();
		print SI_LIST "Special Interest Senior: $TOTAL_SI_SENIOR\n";
	} else {
		print SI_LIST "Special Interest Senior: NA\n";
	}
# Special Interests Skiing
	$STH = $DBH->prepare($SI_SKIING_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_SKIING = $STH->fetchrow();
		print SI_LIST "Special Interest Skiing: $TOTAL_SI_SKIING\n";
	} else {
		print SI_LIST "Special Interest Skiing: NA\n";
	}
# Special Interests Spa
	$STH = $DBH->prepare($SI_SPA_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_SPA = $STH->fetchrow();
		print SI_LIST "Special Interest Spa: $TOTAL_SI_SPA\n";
	} else {
		print SI_LIST "Special Interest Spa: NA\n";
	}
# Special Interests Sport
	$STH = $DBH->prepare($SI_SPORT_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_SPORT = $STH->fetchrow();
		print SI_LIST "Special Interest Sport: $TOTAL_SI_SPORT\n";
	} else {
		print SI_LIST "Special Interest Sport: NA\n";
	}
# Special Interests Travel Tips
	$STH = $DBH->prepare($SI_TRAVEL_TIPS_QUERY);
	$STH->execute($BEGIN_DATE,$END_DATE) or die "Couldn't execute statement: " . $STH->errstr;
	unless ($STH->rows == 0) {
		$TOTAL_SI_TRAVEL_TIPS = $STH->fetchrow();
		print SI_LIST "Special Interest Travel Tips: $TOTAL_SI_TRAVEL_TIPS\n";
	} else {
		print SI_LIST "Special Interest Travel Tips: NA\n";
	}
++$COUNT;
print SI_LIST "\n";
}
# Reset Counter
#	$COUNT = "0"
print SI_LIST "\n\nReport compiled: $REPORT_DATE\n";
close(SI_LIST);
print "Writing out Report for Special Interests to /tmp/special_interests_breakdown_$YEAR.txt\n";
