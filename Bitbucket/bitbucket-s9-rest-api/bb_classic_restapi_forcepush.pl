#!/usr/bin/perl

# This is a copy of the bb_classic_restapi_hooks.pl script, just specific to forcepush
# As I may need to unset this everywhere to allow syncing to happen, and then re-set it where appropriate
# as part of the migration.

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
my $outfile = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/force_push_hook_' . $date . '.log';
open(OUTFILE, ">$outfile");

get_repo_names();
get_repo_hooks();
#set_repo_group_perms();  # This is invoked by get_repo_group_perms()
#set_repo_user_perms();  # This is invoked by get_repo_user_perms()
close(OUTFILE);

sub get_repo_names {
    $client->GET(
        '/rest/api/1.0/repos?limit=100', 
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
            #print 'Filtered ' . $reponame . 'is in ' . $projectkey . "\n";
            $repo_hash{$reponame} = $projectkey;
        }
    }
}

sub get_repo_hooks {
    for my $reponame(keys %repo_hash) {
        my $projectkey = $repo_hash{$reponame};
        # /rest/api/1.0/projects/{projectKey}/repos/{reponame}/settings/hooks
        $client->GET(
            '/rest/api/1.0/projects/' . $projectkey . '/repos/' . $reponame . '/settings/hooks', 
            $headers
        );
    
        my $hook_data = from_json($client->responseContent());
        #print Dumper $hook_data;
        for ( @{$hook_data->{values}}) {
            my $hook_key = $_->{details}->{key};
            my $hook_type = $_->{details}->{type};
            if($hook_key eq 'com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook') {
                get_repo_hook_setting($hook_key, $projectkey, $reponame);
            }
        }
    sleep 1;
    }
}

sub get_repo_hook_setting {
    my $hook_key = scalar($_[0]); 
    my $projectkey = scalar($_[1]); 
    my $reponame = scalar($_[2]); 
    $client->GET(
            '/rest/api/1.0/projects/' . $projectkey . '/repos/' . $reponame . '/settings/hooks/' . $hook_key, 
            $headers
    );
    my $hook_status = from_json($client->responseContent());
    my $enable_check = $_->{enabled};
    my $configured_check = $_->{configured};
    my $hook_name = $_->{details}->{name};
    if ($enable_check) {
       print 'For ' . $projectkey . ':' . $reponame . ' -- ' . $hook_name . ' is enabled ' . '(hook key = ' . $hook_key . ')' . "\n";
       print OUTFILE 'For ' . $projectkey . ':' . $reponame . ' -- ' . $hook_name . ' is enabled ' . '(hook key = ' . $hook_key . ')' . "\n";
       # PUT requests just error out in perl, plan is to switch to python for applying changes
       #set_repo_hooks($projectkey, $reponame, $hook_key, $hook_name);
    }
    sleep 2;
}

# PUT requests just error out in perl, plan is to switch to python for applying changes
# The following function is currently unusued.

sub set_repo_hooks {
    my $username = $ldap_username;
    my $password = $ldap_password;
    my $headers = {Accept => 'application/json', 'Content-Type' => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
    #my $client = REST::Client->new();
    $client->setHost('https://bitbucket001.prod-iad.gs.nsgbu.internal');
    # add a CA to verify server certificates
    $client->setCa('/Users/mrex/GIT/SE/netsuite-configuration/salt/shared/state/technology/bitbucket/files/SEAD_CA.crt');
    my $projectkey = scalar($_[0]);
    my $reponame = scalar($_[1]);
    my $hook_key = scalar($_[2]);
    my $hook_name = scalar($_[3]);

   print '-- In ' . $projectkey . ':' . $reponame . ' enabling ' . $hook_name . "\n";
   # bitbucket API PUT though the perl never seems to succeed.
   # I have lost far too much time figuring this out.
   # Enable Hooks
   #  /rest/api/1.0/projects/{projectKey}/repos/{repositorySlug}/settings/hooks/{hookKey}/enabled
   $client->PUT(
       '/rest/api/1.0/projects/' . $projectkey . '/repos/' . $reponame . '/settings/hooks/' . $hook_key . '/enabled',
       $headers
   );
   print 'PUT https://bitbucket001.prod-iad.gs.nsgbu.internal/rest/api/1.0/projects/' . $projectkey . '/repos/' . $reponame . '/settings/hooks/' . $hook_key . '/enabled' . "\n";
   if( $client->responseCode() eq '200' ){
       print '-- In ' . $projectkey . ':' . $reponame . ' enabling ' . $hook_name . "\n";
       print OUTFILE '-- In ' . $projectkey . ':' . $reponame . ' enabling ' . $hook_name . "\n";
       # Expected output
       # curl -k -X PUT -H "Authorization: Basic bXJleDpXMW5uYSgpMA==" -H "Content-Type: application/json" "https://bitbucket.prod-iad.gs.nsgbu.internal/rest/api/1.0/projects/SDDC/repos/netsuite-configuration/settings/hooks/com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook/enabled"
       #{"details":{"key":"com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook","name":"Reject Force Push","type":"PRE_RECEIVE","description":"Reject all force pushes (git push --force) to this repository","version":"5.16.11","configFormKey":null,"scopeTypes":["REPOSITORY","PROJECT"]},"enabled":true,"configured":false,"scope":{"type":"REPOSITORY","resourceId":138}}
   } else {
       print 'Failed to update ' . $hook_name . ' in ' . $projectkey . ':' . $reponame . "\n";
       print OUTFILE 'Failed to update ' . $hook_name . ' in ' . $projectkey . ':' . $reponame . "\n";
       print "Error: Return code is : " . $client->responseCode() . "\n";
       foreach ( $client->responseHeaders() ) {
           print 'Header: ' . $_ . '=' . $client->responseHeader($_) . "\n";
       }
       # I am getting 500 responses, and I do not know why.
       # Any content is appearently text/plain and not application/json
       # but it is not a scalar either.  Maybe it is an array or a hash?
  
       # Is this a cert problem?  'curl -k' works as it is insecure.
       # Maybe rest_client cannot handle "*.internal" ?
       # Is there a flag I can set for the perl module to be OK with this?

       #my $response = from_json($client->responseContent());
       #print $client->responseContent() . "\n";
       #for ( @{$response->{errors}}) {
       #    my $http_error = $_->{message};
       #    print 'Error message: ' . $http_error . "\n";
       #}
       #print "Content: \n" .$client->responseContent() . "\n"; # This currently returns an error: Not a SCALAR reference
       #foreach ( $client->responseContent() ) {
       #    #print 'Error Message: ' . $_ . '=' . $client->responseContent($_) . "\n";
       #    print 'Error Message: ' . $_ . $client->responseContent($_) . "\n";
       #}
       print Dumper($client->responseContent());
   }
   sleep 2;
}
