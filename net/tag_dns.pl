#! /usr/bin/perl

# Pull in DNS files, look for KS records, and update db_version where appropriate.

use strict;
use warnings;
use File::Glob ':glob';

my $DNS_DIR = '/Users/mrex/GIT/SE/configuration_data/nameserver/zonedata';
#my @ZONEFILES = bsd_glob("$DNS_DIR/*/*.com", GLOB_NOSORT);
my @ZONEFILES = bsd_glob("$DNS_DIR/SC9/*.com", GLOB_NOSORT);
my $DB_HOSTS_FILE = '/Users/mrex/Documents/SE/SYSCONF-60/sorted3-hosts.txt';
my @DB_HOSTS;
my $DB_HOST;
my $FILE;
my $NEW_FILE;
my $RECORD;
my $NEW_RECORD;
my $MATCH;
my $KS_RECORD;

# Records look like this
#db.prod.dub.netledger.com:db014.prod.dub.netledger.com.                               KS        "ks=os@oel6u6|part@db|fio_format@YES|nas0@fs033x.prod.dub.netledger.com|bond0_a@14:02:EC:32:9E:B8|bond0_b@14:02:EC:32:9E:B9|db_version@11"
#db.prod.dub.netledger.com:db025.prod.dub.netledger.com.                               KS        "ks=os@oel6u6|part@sbdb_withssd_fusion|fio_format@YES|nas0@fs041x.prod.dub.netledger.com|bond0_a@94:18:82:0a:fb:e0|bond0_b@94:18:82:0a:fb:e1|db_version@18"

open(ZFILE, $DB_HOSTS_FILE);
while(<ZFILE>) {
        $FILE = $_;
	chomp($FILE);
	push(@DB_HOSTS,$FILE);
	#print "$FILE";
}
close(ZFILE);

foreach $DB_HOST(@DB_HOSTS) {
	#print "$DB_HOST";
	foreach $FILE(@ZONEFILES) {
		#print "--$FILE\n";
		open(ZONEFILE, $FILE);
		$NEW_FILE = "$FILE.new";
		open(NEWFILE, "> $NEW_FILE");
		while(<ZONEFILE>) {
			$RECORD = $_;
			chomp($RECORD);
			if($RECORD =~ /$DB_HOST.\s+KS\s+"(ks=.*")/) {
				$KS_RECORD = $1;
				if($KS_RECORD =~ /db_version/) {
					#print "I found $DB_HOST in $FILE\n\n--$RECORD\n";
					if($KS_RECORD =~ /db_version\@11/) {
						#print "$DB_HOST: record with db_version 11, should be 11.2.\n";
						$NEW_RECORD = $RECORD;
						$NEW_RECORD =~ s/db_version\@11/db_version\@11.2/;
						print NEWFILE "$NEW_RECORD\n";
					} elsif($KS_RECORD =~ /db_version\@18.1/) {
						#print "$DB_HOST: record with db_version 18.1 already set.\n";
						print NEWFILE "$RECORD\n";
					} elsif($KS_RECORD =~ /db_version\@18/) {
						#print "$DB_HOST: record set to 18, should be 18.1\n";
						$NEW_RECORD = $RECORD;
						$NEW_RECORD =~ s/db_version\@18/db_version\@18.1/;
						print NEWFILE "$NEW_RECORD\n";
					} else {
						print "ERROR -- $KS_RECORD\n\n";
					}
				} else {
					#print "$DB_HOST: Please set to 18.1\n";
					$NEW_RECORD = $RECORD;
					$NEW_RECORD =~ s/"$/\|db_version\@18.1"/;
					print NEWFILE "$NEW_RECORD\n";
				}
			} else {
				print  NEWFILE "$RECORD\n"; 
			}
		}
		close(ZONEFILE);
		rename($NEW_FILE, $FILE);
	}
}
