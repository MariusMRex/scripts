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
my $outfile = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/hooks_by_repo_' . $date . '.log';
my $outfile_latest = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/hooks_by_repo_latest';
open(OUTFILE, ">$outfile");

get_repo_names();
get_repo_hooks();
#set_repo_group_perms();  # This is invoked by get_repo_group_perms()
#set_repo_user_perms();  # This is invoked by get_repo_user_perms()
close(OUTFILE);
symlink_log();


sub symlink_log {
    unlink($outfile_latest);
    symlink($outfile, $outfile_latest);
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
            #print 'Filtered ' . $reponame . 'is in ' . $projectkey . "\n";
            $repo_hash{$reponame} = $projectkey;
        }
    }
}

sub get_repo_hooks {
    for my $reponame(keys %repo_hash) {
        my $projectkey = $repo_hash{$reponame};
        #print OUTFILE 'In ' . $projectkey . ':' . $reponame . "\n";
        #print 'Reponame ' . $reponame . ' is in project '  . $projectkey . "\n";
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
            #print OUTFILE '-- ' . $hook_type . ' is present with '  . $hook_key . "\n";
            #print '-- ' . $hook_type . ' is present with '  . $hook_key . "\n";
            #get_repo_hook_setting($hook_key, $hook_type, $projectkey, $reponame);
            get_repo_hook_setting($hook_key, $projectkey, $reponame);
        }
    #print Dumper $group_perms;
    sleep 1;
    }
}

sub get_repo_hook_setting {
    my $hook_key = scalar($_[0]); 
    my $projectkey = scalar($_[1]); 
    my $reponame = scalar($_[2]); 
    #print 'Fetching hook settings for ' . $projectkey . ':' . $reponame . ' with hook_key ' . $hook_key . "\n";
    #print OUTFILE 'Fetching hook settings for ' . $projectkey . ':' . $reponame . ' with hook_key ' . $hook_key . "\n";
    $client->GET(
            '/rest/api/1.0/projects/' . $projectkey . '/repos/' . $reponame . '/settings/hooks/' . $hook_key, 
            $headers
    );
    my $hook_status = from_json($client->responseContent());
    #print Dumper $hook_status;
    #for ( @{$hook_status->{values}}) {
    #for ( @{$hook_status}) {
    #    print "In For Loop...\n";
    my $enable_check = $_->{enabled};
    my $configured_check = $_->{configured};
    my $hook_name = $_->{details}->{name};
    #print $hook_name;
    #print ' enabled = ' . $enable_check . "\n";
    #print $enable_check . "\n";
    if ($enable_check) {
       print 'For ' . $projectkey . ':' . $reponame . ' -- ' . $hook_name . ' is enabled ' . '(hook key = ' . $hook_key . ')' . "\n";
       print OUTFILE 'For ' . $projectkey . ':' . $reponame . ' -- ' . $hook_name . ' is enabled ' . '(hook key = ' . $hook_key . ')' . "\n";
       # PUT requests just error out in perl, plan is to switch to python for applying changes
       #set_repo_hooks($projectkey, $reponame, $hook_key, $hook_name);
    #} else {
    #   print 'For ' . $reponame . ' in ' . $projectkey . " :\n";
    #   print 'Hook enable check returned: ' .  $enable_check . "\n";
    }
    #}
    #print Dumper $hook_status;
    #print "----\n";
    sleep 2;
}

# PUT requests just error out in perl, plan is to switch to python for applying changes
# The functions below here are not used, see bb_oci_restapi_put_hooks.py instead

## Hook not configured:
#curl -D- -X GET -H "Authorization: Basic bXJleDpXMW5uYSgpNw==" -H "Content-Type: application/json" https://nacl-c001.adm.svale.netledger.com/rest/api/1.0/projects/SED/repos/gpg-signing-test/settings/hooks/com.atlassian.bitbucket.server.bitbucket-bundled-hooks:verify-committer-hook

## Hook configured:
#curl -D- -X GET -H "Authorization: Basic bXJleDpXMW5uYSgpNw==" -H "Content-Type: application/json" https://nacl-c001.adm.svale.netledger.com/rest/api/1.0/projects/SED/repos/gpg-signing-test/settings/hooks/com.atlassian.bitbucket.server.bitbucket-gpg:verify-gpg-signature-hook

# When we start the PUT change
#    print OUTFILE "PUT /rest/api/1.0/projects/{projectKey}/settings/hooks/{hookKey}/enabled\n";

# I am getting permission problems, even though I have confirmed that my LDAP login is still viable.
sub set_repo_hooks {
    my $username = $ldap_username;
    my $password = $ldap_password;
    my $headers = {Accept => 'application/json', 'Content-Type' => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
    my $client = REST::Client->new();
    $client->setHost('https://bitbucket001.prod-iad.gs.nsgbu.internal');
    # add a CA to verify server certificates
    $client->setCa('/Users/mrex/GIT/SE/netsuite-configuration/salt/shared/state/technology/bitbucket/files/SEAD_CA.crt');
    my $projectkey = scalar($_[0]);
    my $reponame = scalar($_[1]);
    my $hook_key = scalar($_[2]);
    my $hook_name = scalar($_[3]);

   print '-- In ' . $projectkey . ':' . $reponame . ' enabling ' . $hook_name . "\n";
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
   } else {
       print 'Failed to update ' . $hook_name . ' in ' . $projectkey . ':' . $reponame . "\n";
       print OUTFILE 'Failed to update ' . $hook_name . ' in ' . $projectkey . ':' . $reponame . "\n";
       print "Error: Return code is : " . $client->responseCode() . "\n";
       foreach ( $client->responseHeaders() ) {
           print 'Header: ' . $_ . '=' . $client->responseHeader($_) . "\n";
       }
       # I am getting 500 responses, and I do not know why.
       # Any content is appearently text/plain and not application/json
       # but it is not a scaler either.  Maybe it is an array or a hash?
       my $response = from_json($client->responseContent());
       for ( @{$response->{errors}}) {
           my $http_error = $_->{message};
           print 'Error message: ' . $http_error . "\n";
       }
       #print "Content: \n" .$client->responseContent() . "\n"; # This currently returns an error: Not a SCALAR reference
   }
   sleep 2;
}

