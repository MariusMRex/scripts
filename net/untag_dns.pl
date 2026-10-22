#! /usr/bin/perl

# Pull in DNS files, look for KS records, and update db_version where appropriate.
#
# This script is, in a way, the opposite of tag_dns.pl.  My effort to update DNS tags has been 
# upended by the procimation that using DNS to record DB version is to be undone.  Thus I am
# removing DNS tags with this script.

use strict;
use warnings;
use File::Glob ':glob';

my $DNS_DIR = '/Users/mrex/GIT/SE/configuration_data/nameserver/zonedata';
my $ZONE = $ARGV[0];

# Make sure an augent of the zone is provided
unless($ZONE =~ /AM3|BO1|CH1|DU3|SC9|SE4/) {
	print "Augment of zone to search required.\n";
	print "Viable zone are AM3, BO1, CH1, DU3, SC9, or SE4.\n";
	exit(1);
} else {
	chomp($ZONE);
}

my @ZONEFILES = bsd_glob("$DNS_DIR/$ZONE/*.com", GLOB_NOSORT);
my $FILE;
my $NEW_FILE;
my $RECORD;
my $NEW_RECORD;
my $KS_RECORD;

# Records look like this
#db.prod.dub.netledger.com:db014.prod.dub.netledger.com.                               KS        "ks=os@oel6u6|part@db|fio_format@YES|nas0@fs033x.prod.dub.netledger.com|bond0_a@14:02:EC:32:9E:B8|bond0_b@14:02:EC:32:9E:B9|db_version@11"
#db.prod.dub.netledger.com:db025.prod.dub.netledger.com.                               KS        "ks=os@oel6u6|part@sbdb_withssd_fusion|fio_format@YES|nas0@fs041x.prod.dub.netledger.com|bond0_a@94:18:82:0a:fb:e0|bond0_b@94:18:82:0a:fb:e1|db_version@18"

foreach $FILE(@ZONEFILES) {
	#print "--$FILE\n";
	open(ZONEFILE, $FILE);
	$NEW_FILE = "$FILE.new";
	open(NEWFILE, "> $NEW_FILE");
	while(<ZONEFILE>) {
		$RECORD = $_;
		chomp($RECORD);
		if($RECORD =~ /.*\s+KS\s+"ks=.*db_version\@.*"/) {
			#print "KS record with db_version found\n";
			$NEW_RECORD = $RECORD;
			$NEW_RECORD =~ s/\|db_version\@\d\d\.\d//;
			#print "OLD = $RECORD\n";
			#print "NEW = $NEW_RECORD\n";
			print NEWFILE "$NEW_RECORD\n";
		} else {
			print  NEWFILE "$RECORD\n"; 
		}
	}
	close(ZONEFILE);
	rename($NEW_FILE, $FILE);
}
