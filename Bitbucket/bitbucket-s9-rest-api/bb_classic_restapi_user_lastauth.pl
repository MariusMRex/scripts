#!/usr/bin/perl

# This is a quick copy of the bb_classic_restapi_user_emails.pl to grab last login
# As I know that script pulls valid users, and not just any AD users, pulling from the bb_* groups
# is not the worst idea.
# 
# As a more general query like one to https://nacl-c001.adm.svale.netledger.com/rest/api/1.0/admin/users?limit=500
# is TOTALLY OK with saying a user that has never logged in is active=TRUE and type=NORMAL.  The only indicator is the lack of a lastAuthenticationTimestamp
#
# Something is still wrong with the $dated_login variable, but I do not know what.
# - It may be that epoc time reported by bitbucket is returned in milliseconds as:
# - 1659276000000 milliseconds = Sunday, July 31, 2022 2:00:00 PM
# - 1659276000 seconds = Sunday, July 31, 2022 2:00:00 PM

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

#my $reviewerToRemove = $ARGV[0];
my $username = $ad_username;
my $password = $ad_password;
my $headers = {Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
my $client = REST::Client->new();
$client->setHost('https://nacl-c001.adm.svale.netledger.com');
# add a CA to verify server certificates
$client->setCa('/usr/local/etc/openssl/cert.pem');
my @group_list;
my @email_list;
my $email_list_unique;
my $query_limit = '&limit=300';  # Max number of records to return from a API query

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
# Mac time manipulation has a unique interface (That I appearently am not groking right now.)
#my $timestamp = `/bin/date +%s`
#my $timestamp_minus_8_weeks = `/bin/date -j  -v -8w +%s`;
my $time = time();
# If a day has 86,400 seconds, 8 weeks = 4,838,400
my $timestamp_minus_8_weeks = $time - 4838400;
my $time_goal = localtime($timestamp_minus_8_weeks);
print "Looking for users who have not logged in since $timestamp_minus_8_weeks: $time_goal\n"; 
my $outfile = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/user_last_logins_' . $date . '.csv';


# subroutines to run
get_active_users;
get_group_members();

####
## Just subroutines below this line
####

sub get_active_users {
    $client->GET(
        '/rest/api/1.0/groups?filter=bb_' . $query_limit, 
        $headers
    );

    #{
    #  "size": 3,
    #  "limit": 3,
    #  "isLastPage": false,
    #  "values": [
    #    {
    #      "name": "bb_ dba_dbe_admin",
    #      "deletable": true
    #    },
    #    {
    #      "name": "bb_cfd_configurationdata_admin",
    #      "deletable": true
    #    },
    #    {
    #      "name": "bb_cfd_configurationdata_merge",
    #      "deletable": true
    #    }
    #  ],
    #  "start": 0,
    #  "nextPageStart": 3
    #}
    #my $groups = from_json($client->responseContent());
    #for ( @{$groups->{values}}) {
    #    my $groupname = $_->{name};
    #    #my $bb_groupname = $1;
    #    push(@group_list,$groupname);
    #}
    # So I might as well just parse the answer as a string,
    my @groups = split(/,/, $client->responseContent());
    foreach my $group(@groups) {
       chomp($group);
       if($group =~ m/"(bb_\w+)"$/) {
           my $groupname = $1;
           #print "Found:" . $groupname . "\n";
           push(@group_list,$groupname);
       }
    }
}

# Sample group member output
# After trim_response(), that is
#{
#  "values": [
#    {
#      "name": "dpocock",
#      "emailAddress": "dpocock@netsuite.com",
#      "id": 3321,
#      "displayName": "Pocock, David",
#      "active": true,
#      "slug": "dpocock",
#      "type": "NORMAL",
#      "directoryName": "JIRA Server",
#      "deletable": false,
#      "lastAuthenticationTimestamp": 1583801670059,
#      "mutableDetails": false,
#      "mutableGroups": false,
#      "links": {
#        "self": [
#          {
#            "href": "https://nacl-c001.adm.svale.netledger.com/users/dpocock"
#          }
#        ]
#      }
#    }
#  ]
#}
sub get_group_members {
    open(GROUP, ">$outfile");
    foreach my $group(@group_list) {
        #print $group . " loop\n";
        my $count = 0;
        my @group_list;
        #print GROUP $group;
        if($group =~ m/^bb_\w+$/) {
            $client->GET(
                '/rest/api/1.0/admin/groups/more-members?context=' . $group . $query_limit,
                $headers
            );
            #my $response_content = trim_response($client->responseContent());
            #print $response_content . "\n";
            #my $response = from_json($response_content);
            my $response = from_json($client->responseContent());
            #print Dumper $response;
           for ( @{$response->{values}}) {
               #my $member_email = $_->{emailAddress};
               my $member_name = $_->{name};
               my $last_login = $_->{lastAuthenticationTimestamp};
               if($last_login) {
                   my $dated_login = localtime($last_login);
                   if($last_login < $timestamp_minus_8_weeks) {
                   #push(@email_list,$member_email);
                       print $last_login . "-" . $member_name . "-" . $dated_login . "\n";
                       print GROUP $last_login . "-" . $member_name . "-" . $dated_login . "\n"; 
                       ++$count;
                   #} else {
                   #    print "---- $dated_login is fine\n";
                   #    print GROUP "---- $dated_login is fine\n";
                   }
               } else {
                   print "$member_name has never logged in\n";
                   print GROUP "$member_name has never logged in\n";
               }
               #print GROUP $member_email . "\n";
           }
        }
        #print $group . '-- Total members:' . $count . "\n";
        #print GROUP "\n";
        sleep 1;
    }
    close(GROUP);
}
