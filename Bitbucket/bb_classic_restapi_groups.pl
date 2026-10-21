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

#my $reviewerToRemove = $ARGV[0];
my $username = 'mrex';
my $password = 'W1nna()6';
my $headers = {Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
my $client = REST::Client->new();
$client->setHost('https://nacl-c001.adm.svale.netledger.com');
# add a CA to verify server certificates
$client->setCa('/usr/local/etc/openssl/cert.pem');
my @group_list;
my $query_limit = '&limit=300';  # Max number of records to return from a API query

# Lets get some date iformation set
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
#my $outfile = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/group_members_' . $date . '.csv';
my $outfile = 'group_members_' . $date . '.csv';


#if ($#ARGV ne 0) {
#    print "usage: $0 <username>\n";
#    exit 1;
#}

# subroutines to run
get_group_names();
get_group_members();

####
## Just subroutines below this line
####

# Never quite got this to work.
# The idea was, is that a array or hash? Process it accordingly.
# Now that I can successfully parse the JSON I could probbaly
# get this to actually function now.
#sub toList {
#    my $data = shift;
#    my $key = shift;
#    #print "-" . $data . ":" . $key . "\n";
#    if (ref($data->{$key}) eq 'ARRAY') {
#        $data->{$key};
#    } elsif (ref($data->{$key}) eq 'HASH') {
#        [$data->{$key}];
#    } else {
#        [];
#    }
#}

# This should work, I just did not end up using it.
#sub is_last_page {
#    if($_[0] =~ /{.*"nextPageStart":\d+}}/) {
#    }
#}
 
# unneeded   
#sub trim_response {
#    my $json_response = shift;
#    if($json_response =~ /{"size":.*("values":\[.*\]),"start":0}/) {
#        return "{" . $1 . "}";
#    } else {
#	print "Cannot parse response.  Group may be larger that query limit: $query_limit\n";
#        return $json_response;
#    }
#}



sub get_group_names {
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
        print GROUP $group;
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
               my $member_name = $_->{name};
               #print "-" . "member:" . $member_name . "\n";
               print GROUP "," . $member_name;
               ++$count
           }
        }
        print $group . '-- Total members:' . $count . "\n";
        print GROUP "\n";
        sleep 1;
    }
    close(GROUP);
}




###
# Just failed attempts below here
###




#my $response = from_json($client->responseContent());
#foreach my $item( @$response ) { 
#for my $item( @{$response} ) { 
#for my $item( @{$response->{items}} ) { 
#    # fields are in $item->{Year}, $item->{Quarter}, etc.
#    print "Stuff:" .  $item->{name} . "\n";
#}

#print $client->responseContent();
#my $groups = toList($response->{'values'},'valueData');
#my $group;
#foreach $group (@$groups) {
#    if($group =~ /bb*/) {
#        print "Found Group $group\n";
#    } else {
#        print "ERROR: $group\n";
#    }
#}

#use WebService::BitbucketServer;
#
#my $api = WebService::BitbucketServer->new(
#    base_url    => 'https://nacl-c001.adm.svale.netledger.com/',
#    username    => 'mrex',
#    password    => 'W1nna()6',
#);
 
#my $response = $api->core->get_group_names;


#my $api = $auth->core->get_group_names(
#   filter      => 'bb_'
#;

#my $response = $api->core->get_group_names;
#my $app_info = $response->data;
#print "Making API calls to: $app_info->{displayName} $app_info->{version}\n";
#my $response = $api->core->get_group_names;
#my $app_info = $response->data;

 
# Or use the low-level method (useful perhaps for new endpoints
# that are not packaged yet):
 
#my $response = $api->call(method => 'GET', url => 'api/1.0/application-properties');
 
# vim: set filetype=perl sts=4 ts=4 sw=4 tw=0 colorcolumn=100 et :
