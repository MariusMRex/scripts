#!/usr/bin/perl
use strict;
use warnings;

# This script is meant as a replacement for memcache_stats_munin.sh.  The previous script 
# works for responsetime, but that functionality breaks the rest of the script for newer versions of munin.
# This version handles the functions that  memcache_stats_munin.sh errors out on.
# Response time can continue to run in the old script sinec it works fine there, and there
# is no need to reset the current graphs by adding a new script.  Better to let it run.
# Marius 2013-12-11

my @LINES;							# Put the return from 'netcat localhost stats' here
my $LINE;							# A single line of @LINES
my $GET_HIT_RATIO;				# ration of cache hits to misses
my $GET_HITS;						# get_hits will go here
my $GET_MISSES;						# get_misses will go here
my $DEL_HITS;						# delete_hits will go here
my $DEL_MISSES;						# delete_misses will go here
my $INCR_HITS;						# incr_hits will go here
my $INCR_MISSES;					# incr_missess will go here
my $DECR_HITS;						# decr_hits will go here
my $DECR_MISSES;					# decr_misses will go here
my $TOTAL_HIT_RATIO;				# ratio of all hits and misses
my $VALUE;							# Value to pass to munin
my $NC = "/usr/bin/nc";				# Where is netcat on this machine?
my $HOST = `hostname -s`;			# What is the hostname?
chomp($HOST);

############################################################### 
# Config block for pulling the correct values

# Which fields to display for this dataset
my %fieldsets = (
        connections  => 'curr_connections',
        items        => 'curr_items',
        evictions    => 'evictions',
        hits         => 'DoNotMatchMe',
);
# The fieldset for 'hits' needs a lots of extra care
$fieldsets{get_hits} = 'get_hits';
$fieldsets{get_misses} = 'get_misses';
$fieldsets{del_hits} = 'delete_hits';
$fieldsets{del_misses} = 'delete_misses';
$fieldsets{incr_hits} = 'incr_hits';
$fieldsets{incr_misses} = 'incr_misses';
$fieldsets{decr_hits} = 'decr_hits';
$fieldsets{decr_misses} = 'decr_misses';

my %titles = (
        connections  => "Memcached Connections on $HOST",
        items        => "Memcached Items on $HOST",
        evictions    => "Evictions by Second on $HOST",
        hits         => "Memcached Hits Ratio on $HOST",
);

# y-axis labels (typically unit of measurement)
my %vlabels = (
        connections  => 'Connections',
        items        => 'Items in RAM',
        evictions    => 'Evictions/s',
        hits         => 'Ratio(%)',
);
###############################################################

my $CALLED_AS = $0 ;
$CALLED_AS   =~ s/.*memcache_stats_munin_//;

if (!exists $fieldsets{$CALLED_AS} || !exists($vlabels{$CALLED_AS}) ) {
	die "Dataset not known.  Perhaps you need to create a symlink and run that, or maybe edit the script to pull out the data you want";
}

if (@ARGV && $ARGV[0] eq 'config'){
        config();
} else {
	reportData();
}


# description:
#   used when the plugin is executed with a 'config' parameter; munin does this 
#   internally to determine field names and how to plot them etc.
# return value:
#   none
sub config {
	print "graph_title $titles{$CALLED_AS}\n";
	print "graph_vlabel $vlabels{$CALLED_AS}\n";
	print "graph_category Memcache\n";
	if($CALLED_AS eq 'connections') {
		print "conn.label Connections\n";
		print "conn.type GAUGE\n";
		print "conn.max 8192\n";
		print "conn.min 0\n";
	} elsif ($CALLED_AS eq 'items') {
		print "items.label Items\n";
		print "items.type GAUGE\n";
		print "items.min 0\n";
	} elsif ($CALLED_AS eq 'evictions') {
		print "evic.label Evictions\n";
		print "evic.type COUNTER\n";
		print "evic.min 0\n";
	}elsif ($CALLED_AS eq 'hits') {
		print "getr.label Get Ratio\n";
		print "getr.type GAUGE\n";
		print "getr.max 100\n";
		print "getr.min 0\n";
		print "totalr.label Total Ratio\n";
		print "totalr.type GAUGE\n";
		print "totalr.max 100\n";
		print "totalr.min 0\n";
	} else {
		die "Cannot find $CALLED_AS for config values";
	}
}

# description:
#   Gets all data, but only reports the interesting stuff
# return value:
#   none
sub reportData {
	@LINES = `$NC $HOST 9191 <<<stats`;
	foreach $LINE(@LINES) {
			chomp($LINE);
			# Compiling the hit ratio requires some calculation.
			if($CALLED_AS eq 'hits') {
				if($LINE =~ /(^.*)?STAT\s+$fieldsets{get_hits}\s+([0-9]+)/) {
					$GET_HITS = $2;
				}
				if($LINE =~ /(^.*)?STAT\s+$fieldsets{get_misses}\s+([0-9]+)/) {
					$GET_MISSES = $2;
				}
				if($LINE =~ /(^.*)?STAT\s+$fieldsets{del_hits}\s+([0-9]+)/) {
					$DEL_HITS = $2;
				}
				if($LINE =~ /(^.*)?STAT\s+$fieldsets{del_misses}\s+([0-9]+)/) {
					$DEL_MISSES = $2;
				}
				if($LINE =~ /(^.*)?STAT\s+$fieldsets{incr_hits}\s+([0-9]+)/) {
					$INCR_HITS = $2;
				}
				if($LINE =~ /(^.*)?STAT\s+$fieldsets{incr_misses}\s+([0-9]+)/) {
					$INCR_MISSES = $2;
				}
				if($LINE =~ /(^.*)?STAT\s+$fieldsets{decr_hits}\s+([0-9]+)/) {
					$DECR_HITS = $2;
				}
				if($LINE =~ /(^.*)?STAT\s+$fieldsets{decr_misses}\s+([0-9]+)/) {
					$DECR_MISSES = $2;
				}
				if(defined $GET_HITS && defined $GET_MISSES && defined $DEL_HITS && defined $DEL_MISSES && defined $INCR_HITS && defined $INCR_MISSES && defined $DECR_HITS && defined $DECR_MISSES) {
					unless($GET_HITS == '0') {  
						$GET_HIT_RATIO= 100 * $GET_HITS / ($GET_HITS + $GET_MISSES);
					} else {
						$GET_HIT_RATIO = '0';
					}
					unless($GET_HITS + $DEL_HITS + $INCR_HITS + $DECR_HITS == '0') {
						$TOTAL_HIT_RATIO = 100 * ($GET_HITS + $DEL_HITS + $INCR_HITS + $DECR_HITS) / ($GET_HITS + $GET_MISSES + $DEL_HITS + $DEL_MISSES + $INCR_HITS + $INCR_MISSES + $DECR_HITS + $DECR_MISSES);					
					} else {
						$TOTAL_HIT_RATIO = '0';
					}
					print "getr.value $GET_HIT_RATIO\n";
					print "totalr.value $TOTAL_HIT_RATIO\n";
				}
				if(defined $GET_HIT_RATIO && defined $TOTAL_HIT_RATIO) {
					# Should be safe to exit cleanly.
					exit 0;
				}
			}
			# If extra calculation is not needed, this stanza will surfice.
			if($LINE =~ /(^.*)?STAT\s+$fieldsets{$CALLED_AS}\s+([0-9]+)/) {
				$VALUE = $2;
				# This script is a drop in replacemnet for another, so we have to 
				# mimic legacy functionality.
				if($CALLED_AS eq 'connections') {
					print "conn.value $VALUE\n";
				}
				if($CALLED_AS eq 'items') {
					print "items.value $VALUE\n";
				}
				if($CALLED_AS eq 'evictions') {
					print "evic.value $VALUE\n";
				}
				exit 0;
			} else {
				next;
			}
	}
}
