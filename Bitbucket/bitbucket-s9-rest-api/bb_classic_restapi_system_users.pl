#!/usr/bin/perl

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
my $count = 0;
my $query_limit = 'limit=1000';  # Max number of records to return from a API query

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
my $outfile = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/bitbucket_local-users' . $date . '.csv';
open(OUTFILE, ">$outfile");


# subroutines to run
get_user_names();

close(OUTFILE);
####
## Just subroutines below this line
####

sub get_user_names {
    #{
    #  "size": 1,
    #  "limit": 1,
    #  "isLastPage": false,
    #  "values": [
    #    {
    #      "name": "!apereira",
    #      "emailAddress": "apereira@netsuite.com",
    #      "id": 9329,
    #      "displayName": "JIRA ADMIN - Pereira, Alejandro",
    #      "active": true,
    #      "slug": "_apereira",
    #      "type": "NORMAL",
    #      "directoryName": "JIRA Server",
    #      "deletable": false,
    #      "mutableDetails": false,
    #      "mutableGroups": false,
    #      "links": {
    #        "self": [
    #          {
    #            "href": "https://nacl-c001.adm.svale.netledger.com/users/_apereira"
    #          }
    #        ]
    #      }
    #    }
    #  ],
    #  "start": 0,
    #  "nextPageStart": 1
    #}
    # Navigatye the paged API, as we have too many users to query for non-paged responses
    my $is_last_page = 0;
    my $start_page = 0;
    print 'Local Users:' . "\n";
    until($is_last_page == 1) {
        #print "GET /rest/api/1.0/admin/users?start=" . $start_page . "\n";
        $client->GET(
            '/rest/api/1.0/admin/users?start=' . $start_page,  
            $headers
        );
        my $response = from_json($client->responseContent());
        #print Dumper $response;
        for ( @{$response->{values}}) {
            my $member_name = $_->{name};
            my $directory = $_->{directoryName};
            if($directory eq "Stash Internal Directory") {
                print $member_name . "\n";
                print OUTFILE $member_name . ",";
                ++$count;
            }
            elsif($directory eq "JIRA Server") {
                ++$count;
            }
            else {
                print "UNKNOWN UNKNOWN UNKNOWN " . $directory . " - " . $member_name ."\n";
                ++$count;
            }
        }
        # The control messages are just scalars.
        if($response->{nextPageStart}) {
            $start_page = $response->{nextPageStart};
            #print "Next page is: " . $start_page . "\n";
        } else {
            $is_last_page = 1;
            print "Fetched last page\n";
        }
    }
    print "\nRecords processed: " . $count . "\n";
    print OUTFILE "\nRecords processed: " . $count . "\n";
    print "Next Start page is: " . $start_page . "\n";
}

# vim: set filetype=perl sts=4 ts=4 sw=4 tw=0 colorcolumn=100 et :
