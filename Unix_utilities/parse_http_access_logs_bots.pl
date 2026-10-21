#!/usr/bin/perl

use strict;
use warnings;
#use Apache::ParseLog;

#my $SERVER_CONFIG_BASE = "/home/mking/SVN/server_config/trunk";
#my $HTTPD_CONFIG_SVN_BASE = "$SERVER_CONFIG_BASE/httpd";
#my $HTTPD_CONF = "$HTTPD_CONFIG_SVN_BASE/conf/httpd.conf";
#my $name;
#my $customlog;
#my $base = new Apache::ParseLog($HTTPD_CONF);

#$|++;
#use Apache::ParseLog;

#$conf = "/home/mking/SVN/server_config/trunk/httpd/conf/httpd_combined.conf"; 
#$base = new Apache::ParseLog($conf);

#$logs = "/var/log/httpd";
#$base = $base->config(customlog => "/var/log/httpd/web01/2011-11-07/shermanstravel.com_access.log",
#					errorlog => "$logs/web01/2011-11-07/shermanstravel.com_error.log");

#$customlog = $base->getCustomLog("combined");
#$customlog = $base->getCustomLog();
#print "$customlog\n";



## I need to pasre some apache access logs.
## STM uses 'combined' log format:
## LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
## Which is HOST Logname User Time "Request" Latest-Status Bytes "referer" "User-agent"
## (See http://httpd.apache.org/docs/2.0/mod/mod_log_config.html#customlog)
##
## access logs for all webservers are pooled on the nfs server in
## /var/log/httpd/web0[1-6]/  (one subsdir for each webserver)

my $STRING = $ARGV[0]; 		# Some known Good referrers: AOLRSS DealNews NYTimesRSS USAToday usat2 USAT2 Mobissimo
my $FILE = $ARGV[1];
# My Log elements
my $BOT;
my $NULL;
my $HOST;
my $LOGNAME;
my $USER;
my $TIME;
my $TIME1;
my $TIME2;
my $GET;
my $REQUEST;
my $REQUEST_STRING;
my $HTTP_VERSION;
my $STATUS;
my $BYTES;
my $REFERER;
my $USER_AGENT;
my $AGENT1;
my $AGENT2;
my $AGENT3;
my $AGENT4;
my $AGENT5;
my $AGENT6;
my $AGENT7;
my $AGENT8;
my $AGENT9;
my $AGENT10;
my $AGENT11;
my $AGENT12;
my $AGENT13;
my $AGENT14;
my $AGENT15;
my $FOUND_BOT;
my $LINE_COUNT = "0";
my $AOL_REFERER_COUNT = "0";
my $PARTNER_REFERER_COUNT = "0";
my $EMPTY_REFERRER_COUNT = "0";
my $OTHER_REFERRER_COUNT = "0";
my $NO_AGENT_COUNT = "0";
my $NO_REFERRER_COUNT = "0";
my $OLD_BOT_COUNT = "0";
my $NEW_BOT_COUNT = "0";
my $NON_BOT_COUNT = "0";

open(LOGFILE, "$FILE");
LOGLINE: while(<LOGFILE>) {
	++$LINE_COUNT;
# Reset Found Bot status
	$FOUND_BOT = "N";
	($NULL,$HOST,$LOGNAME,$USER,$TIME1,$TIME2,$GET,$REQUEST_STRING,$HTTP_VERSION,$STATUS,$BYTES,$REFERER,$AGENT1,$AGENT2,$AGENT3,$AGENT4,$AGENT5,$AGENT6,$AGENT7,$AGENT8,$AGENT9,$AGENT10,$AGENT11,$AGENT12,$AGENT13,$AGENT14,$AGENT15) = split(/\s/);
# Some cleanup/consolidation where it seems appropriate
	$TIME = "$TIME1 $TIME2";
	$REQUEST = "$GET $REQUEST_STRING $HTTP_VERSION";
# I do not know how long the Agent Line will be
# Sometimes the $REQUEST is so long, we do not even get to the other fields
	if($AGENT15) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3 $AGENT4 $AGENT5 $AGENT6 $AGENT7 $AGENT8 $AGENT9 $AGENT10 $AGENT11 $AGENT12 $AGENT13 $AGENT14 $AGENT15";
	} elsif($AGENT14) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3 $AGENT4 $AGENT5 $AGENT6 $AGENT7 $AGENT8 $AGENT9 $AGENT10 $AGENT11 $AGENT12 $AGENT13 $AGENT14";
	} elsif($AGENT13) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3 $AGENT4 $AGENT5 $AGENT6 $AGENT7 $AGENT8 $AGENT9 $AGENT10 $AGENT11 $AGENT12 $AGENT13";
	} elsif($AGENT12) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3 $AGENT4 $AGENT5 $AGENT6 $AGENT7 $AGENT8 $AGENT9 $AGENT10 $AGENT11 $AGENT12";
	} elsif($AGENT11) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3 $AGENT4 $AGENT5 $AGENT6 $AGENT7 $AGENT8 $AGENT9 $AGENT10 $AGENT11";
	} elsif($AGENT10) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3 $AGENT4 $AGENT5 $AGENT6 $AGENT7 $AGENT8 $AGENT9 $AGENT10";
	} elsif($AGENT9) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3 $AGENT4 $AGENT5 $AGENT6 $AGENT7 $AGENT8 $AGENT9";
	} elsif($AGENT8) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3 $AGENT4 $AGENT5 $AGENT6 $AGENT7 $AGENT8";
	} elsif($AGENT7) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3 $AGENT4 $AGENT5 $AGENT6 $AGENT7";
	} elsif($AGENT6) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3 $AGENT4 $AGENT5 $AGENT6";
	} elsif($AGENT5) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3 $AGENT4 $AGENT5";
	} elsif($AGENT4) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3 $AGENT4";
	} elsif($AGENT3) {
		$USER_AGENT = "$AGENT1 $AGENT2 $AGENT3";
	} elsif($AGENT2) {
		$USER_AGENT = "$AGENT1 $AGENT2";
	} elsif($AGENT1) {
		$USER_AGENT = "$AGENT1";
	} else {
		$USER_AGENT = "NULL";
	}
# Lets get a count here
	if($USER_AGENT eq "NULL") {
# If we have a null value here, I have no agent to speak of.  In all
# Likelyhood the $REQUEST line was so long the other fields were no included.
		++$NO_AGENT_COUNT;
		next;
	}
# Regex did not work so well since sometimes the request string is so long
# There is no room for other fields.
	#if(/\s(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s(-)\s(-|qa)\s(\[\d{2}\/\w{3}\/\d{4}:\d{2}:\d{2}:\d{2}\s-\d{4}\])\s(\".*\")\s(\d{3})\s(\d+|-)\s(\".*\")\s(\".*\")$/) {
	#	$HOST = $1;
	#	$LOGNAME = $2;
	#	$USER = $3;
	#	$TIME = $4;
	#	$REQUEST = $5;
	#	$STATUS = $6;
	#	$BYTES = $7;
	#	$REFERER = $8;
	#	$USER_AGENT = $9;
	#} else {
	#	print "Line did not match: $_\n";
#		next LOGLINE;
	#}
	if($REQUEST =~ /^\"GET\s.*\?refer=$STRING.*\"/i) {
		++$PARTNER_REFERER_COUNT;
# Do not rule out empty referrers, as bots frequenty have empty referrers
		#if($REFERER eq "\"-\"") {
		#	++$EMPTY_REFERRER_COUNT;
		#} elsif($REFERER =~ /\"http:\/\/travel\.aol\.com.*/) {
# catch travel.aol.com, news.travel.aol.com mail.aol.com etc
		#} elsif($REFERER eq "\"\"") {
		#	++$EMPTY_REFERRER_COUNT;
		#} else {
		if($USER_AGENT =~ /.*(msnbot|slurp|googlebot|sosospider|Alltop|Java|Python-urllib|Pingdom\.com_bot|Yandex|Smarte|Mediapartners-Google|facebookexternalhit|Moozilla|st-scraper|check_http).*/i) {
			++$OLD_BOT_COUNT;
			next LOGLINE;
		}
		if($USER_AGENT =~ /.*(Baiduspider|RSSIncludeBot|HuaweiSymantecSpider|Speedy Spider|YoudaoBot|jikespider|percbotspider).*/i) {
			++$NEW_BOT_COUNT;
			next LOGLINE;
		}
# If we get here, no bots where found
				#print "$USER_AGENT\n";
				#++$OTHER_REFERRER_COUNT;
		++$NON_BOT_COUNT;
		#}
	}
}

print "\n\n";
print "Searching for: refer=$STRING\n";
print "Lines processed: $LINE_COUNT\n";
print "Lines disqualified due to no agent entry: $NO_AGENT_COUNT\n";
print "Lines with $STRING Found: $PARTNER_REFERER_COUNT\n";
#print "$STRING -- Empty referrers found: $EMPTY_REFERRER_COUNT\n";
#print "AOL referrers found: $AOL_TRAVEL_REFERRER_COUNT\n";
#print "Other referrers: $OTHER_REFERRER_COUNT\n";
print "$STRING -- Old Bots found: $OLD_BOT_COUNT\n";
print "$STRING -- New Bots found: $NEW_BOT_COUNT\n";
print "$STRING -- lines that did not match known bots: $NON_BOT_COUNT\n";
