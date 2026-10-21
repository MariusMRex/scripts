#!/usr/bin/perl

use strict;
use warnings;
# Adapted from https://developer.atlassian.com/server/fisheye-crucible/writing-a-rest-client-in-perl/
# Official Docs:  https://docs.atlassian.com/bitbucket-server/rest/7.2.3/bitbucket-default-reviewers-rest.html
# this is adapted from my main script bb_classic_restapi_default_reviewer.pl, as it existed in on 2020-07-01
#
# It looks like The best way to remove a default reviewer is to delete the list and recreate it without the user.
# That seems uglier than I want to attempt today, so I guess this will just list the user and where it is found for now.
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
my @project_list;
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
#my $outfile = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/default_reviewers_' . $date . '.txt';
my %repo_hash;
my @delete_me;
my $projectkey;
my $reponame;
my $reviewer;
my $user_to_delete;
#open(OUTFILE, ">$outfile");

if($ARGV[0]) {
    $user_to_delete = $ARGV[0];
    print 'Searching for ' . $user_to_delete . ' as a default reviewer.' . "\n";
}else{
    print 'No user specified.  Thus I will just report reviewers found.'. "\n";
    $user_to_delete = 'no-one';
}
    
get_repo_names();
get_repo_reviewers();
#delete_default_reviewer();
#close(OUTFILE);

sub get_repo_names {
    $client->GET(
        '/rest/api/1.0/repos?limit=100',
        $headers
    );

    my $repos = from_json($client->responseContent());
    for ( @{$repos->{values}}) {
        $reponame = $_->{name};
        $projectkey = $_->{project}->{key};
        # Filter out unwanted repos
        if($reponame =~ /DEPRECATED.*/) {
            next;
        }
        unless($projectkey =~ m/ARKV|JZTES|USERS/) {
            $repo_hash{$reponame} = $projectkey;
        }
    }
}

# I had a lot of trouble parsing this.  Each [ ] is an array and each { } is a hash
# So it was and array, with nested hashes, with reviewers nesting hashes inside of it that nested array values
# The explination here is what helped me: https://www.perlmonks.org/?node_id=1079205
#[
#  {
#    "id": 22,
#    "scope": {
#      "type": "REPOSITORY",
#      "resourceId": 2
#    },
#    "sourceRefMatcher": {
#      "active": true,
#      "id": "ANY_REF_MATCHER_ID",
#      "displayId": "ANY_REF_MATCHER_ID",
#      "type": {
#        "id": "ANY_REF",
#        "name": "Any branch"
#      }
#    },
#    "targetRefMatcher": {
#      "active": true,
#      "id": "refs/heads/master",
#      "displayId": "master",
#      "type": {
#        "id": "BRANCH",
#        "name": "Branch"
#      }
#    },
#    "reviewers": [
#      {
#        "name": "ochalupsky",
#        "emailAddress": "ochalupsky@netsuite.com",
#        "id": 9897,
#        "displayName": "Chalupsky, Ondrej",
#        "active": true,
#        "slug": "ochalupsky",
#        "type": "NORMAL",
#        "links": {
#          "self": [
#            {
#              "href": "https://nacl-c001.adm.svale.netledger.com/users/ochalupsky"
#            }
#          ]
#        }
#      },
#      {
#        "name": "idirbak",
#        "emailAddress": "idirbak@netsuite.com",
#        "id": 5,
#        "displayName": "Dirbak, Ivan",
#        "active": true,
#        "slug": "idirbak",
#        "type": "NORMAL",
#        "links": {
#          "self": [
#            {
#              "href": "https://nacl-c001.adm.svale.netledger.com/users/idirbak"
#            }
#          ]
#        }
#      },
#      *snip*
#      {
#        "name": "cyunker",
#        "emailAddress": "cyunker@netsuite.com",
#        "id": 18544,
#        "displayName": "Yunker, Christopher",
#        "active": true,
#        "slug": "cyunker",
#        "type": "NORMAL",
#        "links": {
#          "self": [
#            {
#              "href": "https://nacl-c001.adm.svale.netledger.com/users/cyunker"
#            }
#          ]
#        }
#      }
#    ],
#    "requiredApprovals": 0
#  }
#]
sub get_repo_reviewers {
    for $reponame(keys %repo_hash) {
        $projectkey = $repo_hash{$reponame};
        $client->GET(
            '/rest/default-reviewers/1.0/projects/' . $projectkey . '/repos/' . $reponame . '/conditions', 
            $headers
        );
    
        my $repo_reviewers = from_json($client->responseContent());
        # First test if data was returned, or if it is just an empty array.
        if($repo_reviewers->[0]->{reviewers}->[0]->{name}) {
            # No repo seems to have more than 3 reviewer groups, so I cap off looking for five
            for (my $i = 0; $i < 5; $i++) {
                # Configuration_data has about 57 default reviewers, so I cap off looking for 75
                for (my $i2 = 0; $i2 < 75; $i2++) {
                    if($repo_reviewers->[$i]->{reviewers}->[$i2]->{name}) {
                        my $reviewer = $repo_reviewers->[$i]->{reviewers}->[$i2]->{name};
                        my $reviewer_id = $repo_reviewers->[$i]->{reviewers}->[$i2]->{id};
                        if($user_to_delete eq 'no-one') {
                            # Run in read only mode and report reviewers
                            print $projectkey . ':' . $reponame . ' Reviewer: ' . $reviewer . ' with ID=' . $reviewer_id . "\n";
                        } elsif($reviewer eq $user_to_delete) {
                            print 'Found ' . $user_to_delete . ' in ' . $projectkey . ':' . $reponame . "\n";
                            #push(@delete_me,$reviewer_id);
                        }
                    }
                }
            }
        }
         
    sleep 2;
    }
}

sub delete_default_reviewer {
    foreach my $delete_id(@delete_me) {
        #print 'Deleting ID ' . $delete_id . "\n";
        # This looks like it would require deleting the whole list and recreating it, which I have not coded.  
        # I am not usre it is worth it.
    }
}
