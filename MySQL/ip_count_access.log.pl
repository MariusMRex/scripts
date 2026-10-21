#!/usr/local/bin/perl 

# Quick script written to access the webserver access logs on nfs server of shermanstravel, and 
# count the IPs we find.  (NFS server has all access logs.)
# User agent strings grabbed from here: http://www.useragentstring.com/pages/Safari/

# Usage: ip_count_access.log.pl $WEBSERVER $DATE (multi)
# Example: ip_count_access.log.pl web01 2011-05-01 multi



my $WEBSERVER = $ARGV[0];
my $LOGDATE = $ARGV[1];
my $MULTILOG = $ARGV[2];
my $LOGBASE = "/var/log/httpd/$WEBSERVER/$LOGDATE";
# awk not working herem lets break it up
# my $IPLIST = `/bin/grep \"Version/3.1 Safari\" $LOGBASE/shermanstravel.com_access.log | /bin/awk \'{print $1}i\' | /bin/sort`;
my $ACCESSLOG_OUT = "accesslog_out.txt";
my $LOGLINES = `/bin/grep \"Version/3.1 Safari\" $LOGBASE/shermanstravel.com_access.log > $ACCESSLOG_OUT`;
#my $LOGLINES = `/bin/grep \"Version/3.1 Safari\" $LOGBASE/*_access.log > $ACCESSLOG_OUT`;
my %IP = ();
my $COUNT = "0";

# Are we working with multiple logs or just one?
if($MULTILOG) {
	print "Working with all known access logs...\n";
	$LOGLINES = `/bin/grep \"Version/3.1 Safari\" $LOGBASE/*_access.log > $ACCESSLOG_OUT`;
} else {
	print "Working with shermanstravel.com_access.log\n";
	$LOGLINES = `/bin/grep \"Version/3.1 Safari\" $LOGBASE/shermanstravel.com_access.log > $ACCESSLOG_OUT`;
}

open(ACCESSLOG, "$ACCESSLOG_OUT");

while(<ACCESSLOG>) {
	chomp;
	# Our accesslog format: LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
	if($MULTILOG) {
		($LOGFILE, $REMOTE_HOST, $REMOTE_LOGNAME, $REMOTE_USER, $TIME, $REQUEST, $LAST_REQUEST, $STATUS, $SIZE_IN_BYTES, $REFERRER, $USER_AGENT) = split;
	} else {
		($REMOTE_HOST, $REMOTE_LOGNAME, $REMOTE_USER, $TIME, $REQUEST, $LAST_REQUEST, $STATUS, $SIZE_IN_BYTES, $REFERRER, $USER_AGENT) = split;
	}
	$IP{$REMOTE_HOST}++
}
close(ACCESSLOG);

for my $COUNT ( sort keys %IP ) {
	print "$COUNT: $IP{$COUNT}\n";
}
