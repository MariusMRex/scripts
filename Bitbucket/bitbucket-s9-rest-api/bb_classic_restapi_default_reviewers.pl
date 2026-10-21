#!/usr/bin/perl

use strict;
use warnings;
# Adapted from https://developer.atlassian.com/server/fisheye-crucible/writing-a-rest-client-in-perl/
# Official Docs:  https://docs.atlassian.com/bitbucket-server/rest/7.2.3/bitbucket-default-reviewers-rest.html
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
my $outfile = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/default_reviewers_' . $date . '.txt';
my %repo_hash;
open(OUTFILE, ">$outfile");
my $reviewer;

#get project_names();  (I checked manually and none of the projects have default reviewers
get_repo_names();
get_repo_reviewers();
close(OUTFILE);

#sub toList {
#    my $data = shift;
#    my $key = shift;
#    if (ref($data->{$key}) eq 'ARRAY') {
#        $data->{$key};
#    } elsif (ref($data->{$key}) eq 'HASH') {
#        [$data->{$key}];
#    } else {
#        [];
#    }
#}

sub get_repo_names {
    $client->GET(
        '/rest/api/1.0/repos?limit=100',
        $headers
    );
    
    unless($client->responseCode() eq '200' ){
        print "Error: Return code is : " . $client->responseCode() . "\n";
        foreach ( $client->responseHeaders() ) {
            print 'Header: ' . $_ . '=' . $client->responseHeader($_) . "\n";
        }
        ## Is a scalar neing returned?
        print "Content: \n" .$client->responseContent() . "\n"; # This currently returns an error: Not a SCALAR reference
        ## Is the response a array?
        #my $response = from_json($client->responseContent());
        #for ( @{$response->{errors}}) {
        #    my $http_error = $_->{message};
        #    print 'Error message: ' . $http_error . "\n";
        #}
        #foreach ( $client->responseContent() ) {
        #    #print 'Error Message: ' . $_ . '=' . $client->responseContent($_) . "\n";
        #    print 'Error Message: ' . $_ . $client->responseContent($_) . "\n";
        #}
    }

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
            #print "filtered " . $reponame. "is in " . $projectkey . "\n";
            $repo_hash{$reponame} = $projectkey;
        }
    }
}

# I had a lot of trouble parsing this.  Each [ ] is an array and each { } is a hash
# So it was an array, with nested hashes, with reviewers nesting hashes inside of it that nested array values
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
    for my $reponame(keys %repo_hash) {
        my $projectkey = $repo_hash{$reponame};
        $client->GET(
            '/rest/default-reviewers/1.0/projects/' . $projectkey . '/repos/' . $reponame . '/conditions', 
            $headers
        );
    
        my $repo_reviewers = from_json($client->responseContent());
        print $projectkey . ":" . $reponame . "\n";
        print OUTFILE $projectkey . ":" . $reponame . "\n";
        #print Dumper $repo_reviewers;
        # This actually pulls the first reviewer, but obviously there can be more than {reviewers}->[0]
        #print '----Reviewer: ' . $repo_reviewers->[0]->{reviewers}->[0]->{name} . "\n";
        # First test if data was returned, or if it is just an empty array.
        if($repo_reviewers->[0]->{reviewers}->[0]->{name}) {
            # No repo seems to have more than 3 reviewer groups, so I cap off looking for five
            for (my $i = 0; $i < 5; $i++) {
                # Fetch the branch to which the following default reviewers applies
                if($repo_reviewers->[$i]->{targetRefMatcher}) {
                    my $branch = $repo_reviewers->[$i]->{targetRefMatcher}->{displayId};
                    my $branch_type = $repo_reviewers->[$i]->{targetRefMatcher}->{type}->{id};
                    print '- For branch: ' . $branch . '(type=' . $branch_type . ')' . "\n";
                    print OUTFILE '- For branch: ' . $branch . '(type=' . $branch_type . ')' . "\n";
                }
                # Configuration_data has about 57 default reviewers, so I cap off looking for 75
                for (my $i2 = 0; $i2 < 75; $i2++) {
                    if($repo_reviewers->[$i]->{reviewers}->[$i2]->{name}) {
                        my $reviewer = $repo_reviewers->[$i]->{reviewers}->[$i2]->{name};
                        print '-- Reviewer: ' . $reviewer . "\n";
                        print OUTFILE '-- Reviewer: ' . $reviewer . "\n";
                    }  
                }
                # Required approvers is an optional field that does not exist if it is '0'
                if($repo_reviewers->[$i]->{requiredApprovals}) {
                    my $required = $repo_reviewers->[$i]->{requiredApprovals};
                    print '--- Required Approvals: ' . $required . "\n";
                    print OUTFILE '--- Required Approvals: ' . $required . "\n";
                # With thew current logic structute for walking arrays, this prints unwanted empty results
                # So I am skipping this for now.
                #} else {
                #    print '-- Required Approvals: 0' . "\n";
                #    print OUTFILE '-- Required Approvals: 0' . "\n";
                }
            }
        } else {
            # If only an empty set is returned by the query, state that explicitly.
            print "---- No default reviewers specified for this repo\n";
            print OUTFILE "---- No default reviewers specified for this repo\n";
        }
         
        # Many other approaches simply did not work.   
        #foreach(@reviewers) {
        #    print '----Reviewer: ' . $_->{name} . "\n";
            #print '----Reviewer: ' . $_ . "\n";

        # Can we find a null response by length?
        #print "Length = " . length($repo_reviewers) . "\n";
        #print "Length = " . scalar($repo_reviewers) . "\n";
        #foreach(@{$repo_reviewers}) {
            #print $_ . "\n";
            #if($_ eq 'reviewers') { 
        #unless(length $repo_reviewers == '2') {
            #my $default_reviewers = toList($repo_reviewers->{'reviewers'},'name');
            #foreach $reviewer (@{$default_reviewers}) {
            #my $default_reviewer = $_->{name};
            #print '-- ' . $default_reviewer;
            #}
        # Many repos lack default reviewers, so skip empty results
        #if($repo_reviewers) {
        #if($default_reviewers) {
            #for ( @{$repo_reviewers->{reviewers}}) {
            #    my $default_reviewer = $_->{name};
                #print '--Default Reviewer' . $default_reviewers . "\n";
            #print $group_perms . "\n";
            #if($group_perms =~ m/PROJECT_\w+$/) {
            #    my $priv_group = $_->{group}->{name};
            #    #print OUTFILE $priv_group . ' has ' . $group_perms . ' in ' . $projectkey . "\n";
            #    set_project_group_perms($projectkey, $group_perms, $priv_group);
            #}
        #}
    #print Dumper $group_perms;
    sleep 5;
    }
}
