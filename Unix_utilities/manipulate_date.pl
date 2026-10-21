#!/usr/local/bin/perl

#use warnings;

$GDATE = gmtime();
$LDATE = localtime();
$DATE = time;
$YSTAMP = time - (3600 * 24);
$YDATE = localtime($YSTAMP);

print "This is GM time: $GDATE\n";
print "This is local time: $LDATE\n";
print "This is the current date in unix timestamp $DATE\n";
print "This is 24 hours ago: $YDATE\n";

# Localtime works like this: ($SEC, $MIN, $HOUR, $MDAY, $MON, $YEAR, $WDAY, $YDAY, $ISDST) = localtime(time);
# Thus to find yesterdays log files that are listed in 'date +%F' format (whatever.log-2011-05-05)
#$YEAR = (0-9999)[(localtime($YSTAMP))[5]];
#$MONTH = (1-12)[(localtime($YSTAMP))[4]];
#$YESTERDAY = (1-31)[(localtime($YSTAMP))[3]];
#print "This is my target logfile: process-bounces-out-$YEAR-$MONTH-$YESTERDAY\n";
$YESTERDAY = ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($YSTAMP);
my $YEAR = $year + 1900;
my $MON = $mon + 1;
print "Year = $YEAR\nMonth = $MON\nYESTERDAY = $mday\n";
print "This is my target logfile: process-bounces-out-$YEAR-$MON-$mday\n";


