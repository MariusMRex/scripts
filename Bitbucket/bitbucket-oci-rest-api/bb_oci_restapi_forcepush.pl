#!/usr/bin/perl

# This is a copy of the bb_classic_restapi_hooks.pl script, just specific to forcepush
# As I may need to unset this everywhere to allow syncing to happen, and then re-set it where appropriate
# as part of the migration.

# I am continuing to have problems doing a PUT to OCI bitbucket.  What if that is the ONLY thing I do?
# This works as is, so GET requests to the OCI bitbucket host seem to work fine.

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

my $username = $ldap_username;
my $password = $ldap_password;
my $headers = {'Content-Type' => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
my $client = REST::Client->new();
$client->setHost('https://bitbucket001.prod-iad.gs.nsgbu.internal');
# add a CA to verify server certificates
$client->setCa('/Users/mrex/GIT/SE/DOCKER/netsuite-configuration/salt/shared/state/technology/bitbucket/files/SEAD_CA.crt');
my %repo_hash;

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
my $outfile = '>>/Users/mrex/Documents/SE/CCS/bitbucket/api-data/put_force_push_hook_' . $date . '.log';
my $datafile = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/hooks_by_repo_2020-08-04.log';
open(OUTFILE, $outfile);

#get_repo_names();
get_repo_hooks();
#set_repo_group_perms(); # This is invoked by get_repo_user_perms()
#set_repo_user_perms();  # This is invoked by get_repo_user_perms()
close(OUTFILE);

sub get_repo_hooks {
    open(LOGFILE, $datafile);
    while(<LOGFILE>) {
        my $line = $_;
        chomp($line);
        if($line =~ /.*\s(\w+):(\w+.*).*\s--\s.*\(hook\skey\s\=\s(.*)\)/) {
            my $projectkey = $1;
            my $reponame = $2;
            my $hook_key = $3;
            #print 'Let us set ' . $projectkey . ':' . $reponame . ' key = ' . $hook_key . "\n";
            #set_repo_hooks($projectkey, $reponame, $hook_key);
        } else {
           print 'NOPE: ' . $line . "\n";
        }
    #sleep 1;
    }
}

#
# PUTS from perl rest_client is just erroring out (2020-08-06)
# I am replacing this with bb_oci_restapi_put_hooks.py instead
# Subroutine below is not in use
#

sub set_repo_hooks {
    my $projectkey = scalar($_[0]);
    my $reponame = scalar($_[1]);
    my $hook_key = scalar($_[2]);

   print '-- In ' . $projectkey . ':' . $reponame . ' enabling ' . $hook_key . "\n";
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
       print '-- In ' . $projectkey . ':' . $reponame . ' enabling ' . $hook_key . "\n";
       print OUTFILE '-- In ' . $projectkey . ':' . $reponame . ' enabling ' . $hook_key . "\n";
       # Expected output
       # curl -k -X PUT -H "Authorization: Basic bXJleDpXMW5uYSgpMA==" -H "Content-Type: application/json" "https://bitbucket.prod-iad.gs.nsgbu.internal/rest/api/1.0/projects/SDDC/repos/netsuite-configuration/settings/hooks/com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook/enabled"
       #{"details":{"key":"com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook","name":"Reject Force Push","type":"PRE_RECEIVE","description":"Reject all force pushes (git push --force) to this repository","version":"5.16.11","configFormKey":null,"scopeTypes":["REPOSITORY","PROJECT"]},"enabled":true,"configured":false,"scope":{"type":"REPOSITORY","resourceId":138}}
   } else {
       print 'Failed to update ' . $hook_key . ' in ' . $projectkey . ':' . $reponame . "\n";
       print OUTFILE 'Failed to update ' . $hook_key . ' in ' . $projectkey . ':' . $reponame . "\n";
       print "Error: Return code is : " . $client->responseCode() . "\n";
       foreach ( $client->responseHeaders() ) {
           print 'Header: ' . $_ . '=' . $client->responseHeader($_) . "\n";
       }
       # I am getting 500 responses, and I do not know why.
       # Any content is appearently text/plain and not application/json
       # but it is not a scalar either.  Maybe it is an array or a hash?
  
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
