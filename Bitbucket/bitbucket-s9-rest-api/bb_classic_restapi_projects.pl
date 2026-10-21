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
my $outfile = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/project_perms_' . $date . '.csv';
open(OUTFILE, ">$outfile");

get_project_names();
get_project_group_perms();
get_project_user_perms();
#set_project_group_perms();  # This is invoked by get_project_group_perms()
#set_project_user_perms();  # This is invoked by get_project_user_perms()
close(OUTFILE);

sub get_project_names {
    $client->GET(
        '/rest/api/1.0/projects', 
        $headers
    );

    my $projects = from_json($client->responseContent());
    #print Dumper $projects;
    for ( @{$projects->{values}}) {
        my $projectkey = $_->{key};
        #print "$projectkey\n";
        # Filter out unwanted projects
        unless($projectkey =~ m/ARKV|JZTES|USERS/) {
            #print "filtered" . $projectkey . "\n";
            push(@project_list,$projectkey);
        }
    }
}
sub get_project_group_perms {
    print OUTFILE "PUT /rest/api/1.0/projects/{projectKey}/permissions/groups?permission&name\n";
    foreach my $projectkey(@project_list) {
        $client->GET(
            '/rest/api/1.0/projects/' . $projectkey . '/permissions/groups', 
            $headers
        );
    
        my $group_perms = from_json($client->responseContent());
        #print Dumper $group_perms;
        for ( @{$group_perms->{values}}) {
            my $group_perms = $_->{permission};
            #print $group_perms . "\n";
            if($group_perms =~ m/PROJECT_\w+$/) {
                my $priv_group = $_->{group}->{name};
                print OUTFILE $priv_group . ' has ' . $group_perms . ' in ' . $projectkey . "\n";
                set_project_group_perms($projectkey, $group_perms, $priv_group);
            }
        }
    #print Dumper $group_perms;
    sleep 1;
    }
}

sub get_project_user_perms {
    print OUTFILE "PUT /rest/api/1.0/projects/{projectKey}/permissions/users?name&permission\n";
    foreach my $projectkey(@project_list) {
        $client->GET(
            '/rest/api/1.0/projects/' . $projectkey . '/permissions/users', 
            $headers
        );
    
        my $user_perms = from_json($client->responseContent());
        #print Dumper $user_perms;
        for ( @{$user_perms->{values}}) {
            my $user_perms = $_->{permission};
            #print "Found permission: " . $user_perms . "\n";
            if($user_perms =~ m/PROJECT_\w+$/) {
                my $priv_user = $_->{user}->{name};
                print OUTFILE $priv_user . ' has ' . $user_perms . ' in ' . $projectkey . "\n";
                set_project_user_perms($projectkey, $user_perms, $priv_user);
            }
        }
    #print Dumper $group_perms;
    sleep 1;
    }
}



# PUT requests just error out in perl, plan is to switch to python for applying changes
# Subroutines below here are not in use.

sub set_project_group_perms {
    my $username = 'mrex';
    my $password = 'W1nna()8';
    my $headers = {Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
    my $client = REST::Client->new();
    $client->setHost('https://bitbucket001.prod-iad.gs.nsgbu.internal');
    # add a CA to verify server certificates
    $client->setCa('/Users/mrex/GIT/SE/netsuite-configuration/salt/shared/state/technology/bitbucket/files/SEAD_CA.crt');
    my $projectkey = scalar($_[0]);
    my $group_perms = scalar($_[1]);
    my $priv_group = scalar($_[2]);

    print 'Granting ' . $priv_group . ' permission ' . $group_perms . ' on ' . $projectkey . "\n";
#    # Set permissions
#    # /rest/api/1.0/projects/{projectKey}/permissions/groups?permission&name
#    $client->PUT(
#        '/rest/api/1.0/projects/' . $projectkey . '/permissions/groups?permisson=' . $group_perms . "&name=" . $priv_group,
#    );
#
#    if( $client->responseCode() eq '200' ){
#        print "Updated\n";
#        print OUTFILE "$projectkey,$group_perms,$priv_group\n";
#    } else {
#        print "Error: Return code is : " . $client->responseCode() . "\n";
#        print OUTFILE "FAIL: $projectkey,$group_perms,$priv_group\n";
#    }
#    sleep 5;
}

sub set_project_user_perms {
    my $username = $ldap_username;
    my $password = $ldap_password;
    my $headers = {Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
    my $client = REST::Client->new();
    $client->setHost('https://bitbucket001.prod-iad.gs.nsgbu.internal');
    # add a CA to verify server certificates
    $client->setCa('/Users/mrex/GIT/SE/netsuite-configuration/salt/shared/state/technology/bitbucket/files/SEAD_CA.crt');
    my $projectkey = scalar($_[0]);
    my $user_perms = scalar($_[1]);
    my $priv_user = scalar($_[2]);

    
    print 'Granting ' . $priv_user . ' permission ' . $user_perms . ' on ' . $projectkey . "\n";
#    # Set permissions
#    # /rest/api/1.0/projects/{projectKey}/permissions/users?name&permission
#    $client->PUT(
#        '/rest/api/1.0/projects/' . $projectkey . '/permissions/users?name=' . $priv_user . "&permission=" . $user_perms,
#        $headers
#    );
#
#    if( $client->responseCode() eq '200' ){
#        print "Updated\n";
#        print OUTFILE "$projectkey,$priv_user,$user_perms\n";
#    } else {
#        print "Error: Return code is : " . $client->responseCode() . "\n";
#        #print $client->responseHeader('ResponseHeader');
#        print $client->responseContent() . "\n";
#        print OUTFILE "FAIL: $projectkey,$priv_user,$user_perms\n";
#    }
#    sleep 5;
}
