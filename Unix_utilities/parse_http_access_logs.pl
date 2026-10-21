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

my $FILE = $ARGV[0];
# My Log elements
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
my $AGENT2;
my $AGENT3;
my $AGENT4;
my $STRING = "AOLRSS";
my $STRING_COUNT = "0";
my $AOL_REFERER_COUNT = "0";
my $EMPTY_REFERRER_COUNT = "0";
my $AOL_TRAVEL_REFERRER_COUNT = "0";
my $PARTNER_REFERRER_COUNT = "0";
my $OTHER_REFERRER_COUNT = "0";
my $NO_REFERRER_COUNT = "0";

open(LOGFILE, "$FILE");
while(<LOGFILE>) {
	#if($_ =~ /.*$STRING.*/) {
		#print $_;
	++$STRING_COUNT;
	#}
	($NULL,$HOST,$LOGNAME,$USER,$TIME1,$TIME2,$GET,$REQUEST_STRING,$HTTP_VERSION,$STATUS,$BYTES,$REFERER,$USER_AGENT,$AGENT2,$AGENT3,$AGENT4) = split(/\s/);
	#print "host = $HOST\n";
	#print "logname = $LOGNAME\n";
	#print "user = $USER\n";
	#print "time = $TIME1 $TIME2\n";
	#print "Request = $GET $REQUEST $HTTP_VERSION\n";
	#print "Status = $STATUS\n";
	#print "Bytes = $BYTES\n";
	#print "Referer = $REFERER\n";
	#print "Agent = $USER_AGENT $AGENT2 $AGENT3 $AGENT4\n";
	#sleep 3;
	#print "\n\n";

# Some cleanup where necessary
	$TIME = "$TIME1 $TIME2";
	$REQUEST = "$GET $REQUEST_STRING $HTTP_VERSION";

	if($REQUEST =~ /^\"GET\s.*\?refer=AOLRSS.*\"/) {
		++$AOL_REFERER_COUNT;
		if($REFERER eq "\"-\"") {
			++$EMPTY_REFERRER_COUNT;
		#} elsif($REFERER =~ /\"http:\/\/travel\.aol\.com.*/) {
# catch travel.aol.com, news.travel.aol.com mail.aol.com etc
		} elsif($REFERER eq "\"\"") {
			++$EMPTY_REFERRER_COUNT;
		} elsif($REFERER =~ /\"http:\/\/.*\.aol\.com.*/) {
			++$AOL_TRAVEL_REFERRER_COUNT;
		#} elsif($REFERER =~ /.*(dealnews|nytimes|usatoday|dealbase|mobissimo).*/) {
		#	++$PARTNER_REFERRER_COUNT;
		#	print "$REFERER\n";
		} else {
			print "$REFERER\n";
			++$OTHER_REFERRER_COUNT;
		}

	}
}

print "\n\n";
print "Lines processed: $STRING_COUNT\n";
print "AOLRSS clicks found: $AOL_REFERER_COUNT\n";
print "Empty referrers found: $EMPTY_REFERRER_COUNT\n";
print "AOL referrers found: $AOL_TRAVEL_REFERRER_COUNT\n";
#print "Partner referrers found: $AOL_TRAVEL_REFERRER_COUNT\n";
print "Other referrers: $OTHER_REFERRER_COUNT\n";
