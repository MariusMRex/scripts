#!/usr/bin/perl

# Ideally we run this script as pmta user, so that it can read all the logs.  
# Mininal authority that does the entire task

# BUG: File glob is not pulling files, do not know why yet.


use warnings;
use strict;

# Unix tools, platform dependant
my $AWK = "/bin/awk";
my $DATE = "/bin/date";
#my $FIND = "/usr/bin/find";
my $GREP = "/bin/grep";
my $KILL = "/bin/kill";
my $PS = "/bin/ps";

# Derive yesterday's date for output in '/bin/date +%F' format
my $BACKDATED_TIMESTAMP = time - (3600 * 24); 
my $YESTERDAY = (my $sec, my $min, my $hour, my $mday, my $mon, my $year, my $wday, my $yday, my $isdst) = localtime($BACKDATED_TIMESTAMP);
my $YEAR = $year + 1900;	# Correct Year output, it is 'off' by 1900 normally
my $MON = $mon + 1;		# Normally months go from 0-11, I want 1-12
my $MDAY = $mday;		# No converstion necessary, just being consistant
# Make sure $MON and $MDAY are two character expressions
# i.e. May 5, 2011 looks like 05 05 2011.
# This is to match '/bin/date +%F' format
if(length($MON) == "1") {
	print "Need to pad month field: ";
	$MON = "0$MON";
	print "Month now equals $MON\n"
}
if(length($MDAY) == "1") {
	print "Need to pad day of month field: ";
	$MDAY = "0$MDAY";
	print "Day now equals $MDAY\n"
}
my $DATESTAMP = "$YEAR-$MON-$MDAY";			# Mimic '/bin/date +%F' format

# Script specific variables
my $COUNTER = "0";
my $LOG;
my $LOGDIR = "/var/log/pmta";
my $BOUNCE_FILE = "$LOGDIR/bounces-$DATESTAMP";
my $PROCESS_BOUNCES = "> /tmp/processed_bounces.out-$DATESTAMP";
my $LOG_WATCHER = "/usr/local/bin/log_watcher";
my $LOG_WATCHER_PID = `$PS -ef | $GREP -e "$LOG_WATCHER -d -l $LOGDIR/bounces-" | $GREP -v grep | $AWK '{print \$2}'`;
chomp($LOG_WATCHER_PID);
#my @PMTA_LOG = `$FIND $LOGDIR -name 'acct-$DATESTAMP-*.csv'`;
my @PMTA_LOG = <$LOGDIR/acct-$DATESTAMP-[0-9][0-9][0-9][0-9].csv>;

# Kill any lingering log_watcher processes
print "Kill any lingering log_watcher processes\n";
if($LOG_WATCHER_PID) {
	system("$KILL $LOG_WATCHER_PID");
	print "Killed $LOG_WATCHER_PID\n";
}

# Create a log file to place bounce results into
print "Create a log file to place bounce results into\n";
open(BOUNCELOG, ">>$BOUNCE_FILE");

# Restart new log_watcher process
print "Restart new log_watcher process: $LOG_WATCHER -d -l $BOUNCE_FILE $PROCESS_BOUNCES &\n";
system("$LOG_WATCHER -d -l $BOUNCE_FILE $PROCESS_BOUNCES &");
print "Lets give log_watcher a rew seconds to start up...";
sleep 5;
print "Done.\n";

# Lets feed something to the new log_watcher process to read in
print "Lets feed something to the new log_watcher process to read in\n";
foreach $LOG (@PMTA_LOG) {
	# pmta log file to read in
	print "Opening up $LOG for reading\n";
	open(LOGFILE, $LOG);
	# Loop through the logfile
	print "Looping through $LOG\n";
	while(<LOGFILE>) {
		# If we find a bounce result, push it to the bouncefile
		if($_ =~ m/^b,$DATESTAMP\s.*/) {
			#print "Pushing results into  $BOUNCE_FILE\n";
			print BOUNCELOG "$_";
			++$COUNTER
		}
	}
	# Close LOGFILE gracefully so the next one can 
	# open up gracefully
	print "$COUNTER records pushed to $BOUNCE_FILE\n";
	print "Closing up $LOG\n";
	close(LOGFILE);
}

# Close up our bouncelog file handle
print "Closing up $BOUNCE_FILE\n";
close(BOUNCELOG);
