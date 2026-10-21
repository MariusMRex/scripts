#!/usr/bin/perl
# This script is simply a simplified copy of bb_clasic_restapi_repos.pl

use strict;
use warnings;
# Adapted from https://developer.atlassian.com/server/fisheye-crucible/writing-a-rest-client-in-perl/
use REST::Client;
use JSON;
# Data::Dumper makes it easy to see what the JSON returned actually looks like 
# when converted into Perl data structures.
use Data::Dumper;
use MIME::Base64;
# Custom library for centralized auth
# ~/perl5/lib/perl5/BB_REST_AUTH.pm
use BB_REST_AUTH;

my $username = $ad_username;
my $password = $ad_password;
my $headers = {Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
my $client = REST::Client->new();
$client->setHost('https://nacl-c001.adm.svale.netledger.com');
# add a CA to verify server certificates
$client->setCa('/usr/local/etc/openssl/cert.pem');
my %repo_hash;
#my $query_limit = '&limit=300';  # Max number of records to return from a API query

# Lets get some date information set
(my $SEC, my $MIN, my $HOUR, my $MDAY, my $MON, my $YEAR, my $WDAY, my $YDAY, my $ISDST) = localtime(time);
# Some corrections for Date
$YEAR = $YEAR + 1900;    		# Correct Year output, it is 'off' by 1900 normally
$MON = $MON + 1;     			# Normally months go from 0-11, I want 1-12
# Pad certain date fields if they are too short.
if(length($MON) == "1") {
	    $MON = "0$MON";
}
if(length($MDAY) == "1") {
	    $MDAY = "0$MDAY";
}
if(length($HOUR) == "1") {
	    $HOUR = "0$HOUR";
}
if(length($MIN) == "1") {
	    $MIN = "0$MIN";
}
if(length($SEC) == "1") {
	    $SEC = "0$SEC";
}
my $date = "$YEAR-$MON-$MDAY";
my $outfile = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/repo_list_unsorted' . $date . '.csv';
my $outfile_sort = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/repo_list_' . $date . '.csv';
my $outfile_latest = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/repo_list_latest';
my $repocount = 0;
open(OUTFILE, ">$outfile");

get_repo_names();
close(OUTFILE);
symlink_log();

sub symlink_log {
    unlink($outfile_latest);
    system("/usr/bin/sort $outfile > $outfile_sort");
    unlink($outfile);
    symlink($outfile_sort, $outfile_latest);
}

sub get_repo_names {
    $client->GET(
        '/rest/api/1.0/repos?limit=150', 
        $headers
    );

    my $repos = from_json($client->responseContent());
    #print Dumper $repos;
    for ( @{$repos->{values}}) {
        my $reponame = $_->{name};
        my $projectkey = $_->{project}->{key};
        #print "$reponame is in $projectkey\n";
        # Filter out unwanted repos
        if($reponame =~ /DEPRECATED.*/) {
            next;
        }
        unless($projectkey =~ m/ARKV|JZTES|USERS/) {
            print $projectkey . ":" . $reponame . "\n";
            print OUTFILE $projectkey . ":" . $reponame . "\n";
            ++$repocount;
            # repo names are unique, so they are the key that contains the project name
            #$repo_hash{$reponame} = $projectkey;
        }
    }
    print "####\n";
    print "Identified " . $repocount . " repos\n"
}
