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
my $outfile = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/repo_perms_' . $date . '.csv';
my $outfile_latest = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/repo_perms_latest';
my $repocount = 0;
open(OUTFILE, ">$outfile");

get_repo_names();
get_repo_group_perms();
get_repo_user_perms();
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
        #print "$reponame" . " is in " .  $projectkey . "\n";
        # Filter out unwanted repos
        if($reponame =~ /DEPRECATED.*/) {
            next;
        }
        unless($projectkey =~ m/ARKV|JZTES|USERS/) {
            print "filtered " . $reponame . "is in " . $projectkey . "\n";
            ++$repocount;
            $repo_hash{$reponame} = $projectkey;
        }
    }
    print "Identified " . $repocount . " repos\n";
}

sub get_repo_group_perms {
    #print OUTFILE "PUT /rest/api/1.0/projects/{projectKey}/repos/{repositorySlug}/permissions/groups?permission&name\n";
    for my $reponame(keys %repo_hash) {
        #if($reponame =~ /DEPRECATED.*/) {
        #    next;
        #}
        my $projectkey = $repo_hash{$reponame};
        #print 'Reponame ' . $reponame . ' is in project '  . $projectkey . "\n";
        # /rest/api/1.0/projects/{projectKey}/repos/{repositorySlug}/permissions/groups
        $client->GET(
            '/rest/api/1.0/projects/' . $projectkey . '/repos/' . $reponame . '/permissions/groups', 
            $headers
        );
    
        my $group_perms = from_json($client->responseContent());
        #print Dumper $group_perms;
        for ( @{$group_perms->{values}}) {
            my $group_perms = $_->{permission};
            #print $group_perms . "\n";
            if($group_perms =~ m/REPO_\w+$/) {
                my $priv_group = $_->{group}->{name};
                print "--  Group " . $priv_group . ' has ' . $group_perms . ' in ' . $projectkey . ':' . $reponame . "\n";
                print OUTFILE "--  Group " . $priv_group . ' has ' . $group_perms . ' in ' . $projectkey . ':' . $reponame . "\n";
                #set_repo_group_perms($priv_group, $group_perms, $reponame, $projectkey);
            }
        }
    #print Dumper $group_perms;
    sleep 1;
    }
}

sub get_repo_user_perms {
    print OUTFILE "PUT /rest/api/1.0/projects/{projectKey}/repos/{repositorySlug}/permissions/users?name&permission\n";
    for my $reponame(keys %repo_hash) {
        my $projectkey = $repo_hash{$reponame};
        # /rest/api/1.0/projects/{projectKey}/repos/{repositorySlug}/permissions/users?filter
        $client->GET(
            '/rest/api/1.0/projects/' . $projectkey . '/repos/' . $reponame . '/permissions/users', 
            $headers
        );
    
        my $user_perms = from_json($client->responseContent());
        #print Dumper $user_perms;
        for ( @{$user_perms->{values}}) {
            my $user_perms = $_->{permission};
#            #print "Found permission: " . $user_perms . "\n";
            if($user_perms =~ m/REPO_\w+$/) {
                my $priv_user = $_->{user}->{name};
                print '- User ' . $priv_user . ' has ' . $user_perms . ' in ' . $projectkey . ':' . $reponame . "\n";
                print OUTFILE '- User ' . $priv_user . ' has ' . $user_perms . ' in ' . $projectkey . ':' . $reponame . "\n";
                #set_repo_group_perms($priv_user, $user_perms, $reponame, $projectkey);
            }
        }
    #print Dumper $group_perms;
    sleep 1;
    }
}
#



# 
# PUT requests just error out in perl, plan is to switch to python for applying changes
# 

sub set_repo_group_perms {
    my $username = $ldap_username;
    my $passwor = $ldap_password;
    my $headers = {Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
    my $client = REST::Client->new();
    $client->setHost('https://bitbucket001.prod-iad.gs.nsgbu.internal');
    # add a CA to verify server certificates
    $client->setCa('/Users/mrex/GIT/SE/netsuite-configuration/salt/shared/state/technology/bitbucket/files/SEAD_CA.crt');
    my $priv_group = scalar($_[0]);
    my $group_perms = scalar($_[1]);
    my $reponame = scalar($_[2]);
    my $projectkey = scalar($_[3]);

#    print 'Granting ' . $priv_group . ' permission ' . $group_perms . ' on ' . $projectkey . ':' . $reponame . "\n";
    # Set permissions
    # /rest/api/1.0/projects/{projectKey}/repos/{repositorySlug}/permissions/groups?permission&name
    #$client->PUT(
    #    '/rest/api/1.0/projects/' . $projectkey . '/repos/' . $reponame . '/permissions/groups?permisson=' . $group_perms . "&name=" . $priv_group,
    #    $headers
    #);
#
#    if( $client->responseCode() eq '200' ){
#        print "Updated\n";
#        print OUTFILE "$projectkey,$reponame,$group_perms,$priv_group\n";
#    } else {
#        print "Error: Return code is : " . $client->responseCode() . "\n";
#        print $client->responseContent() . "\n";
#        print OUTFILE "FAIL: $projectkey,$reponame,$group_perms,$priv_group\n";
#    }
#    sleep 5;
}

sub set_repo_user_perms {
    my $username = $ldap_username;
    my $passwor = $ldap_password;
    my $headers = {Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
    my $client = REST::Client->new();
    $client->setHost('https://bitbucket001.prod-iad.gs.nsgbu.internal');
    # add a CA to verify server certificates
    $client->setCa('/Users/mrex/GIT/SE/netsuite-configuration/salt/shared/state/technology/bitbucket/files/SEAD_CA.crt');
    my $priv_user = scalar($_[0]);
    my $user_perms = scalar($_[1]);
    my $reponame = scalar($_[2]);
    my $projectkey = scalar($_[3]);

    
#    print 'Granting ' . $priv_user . ' permission ' . $user_perms . ' on ' . $projectkey . ':' . $reponame . "\n";
#    # Set permissions
#    # /rest/api/1.0/projects/{projectKey}/repos/{repositorySlug}/permissions/users?name&permission
#    $client->PUT(
#        '/rest/api/1.0/repos/' . $repokey . '/permissions/users?name=' . $priv_user . "&permission" . $user_perms,
#        $headers
#    );
#
#    if( $client->responseCode() eq '200' ){
#        print "Updated\n";
#    } else {
#        print "Error: Return code is : " . $client->responseCode() . "\n";
#        #print $client->responseHeader('ResponseHeader');
        print $client->responseContent() . "\n";
#    }
    sleep 5;
}
