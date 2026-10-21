#!/usr/bin/perl

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
my $outfile = '>>/Users/mrex/Documents/SE/CCS/bitbucket/api-data/create_project_' . $date . '.log';
#my $datafile = '/Users/mrex/Documents/SE/CCS/bitbucket/api-data/hooks_by_repo_2020-08-04.log';
open(OUTFILE, $outfile);

if($ARGV[0]) {
	my $projectkey = $ARGV[0];
	chomp($projectkey);
	# Replace all space characters with underscores
	$projectkey  =~ s/\s+/_/g;
	# Replace wierd charcaters with underscores
	$projectkey =~ s/~/_/g;
	$projectkey =~ s/\(/_/g;
	$projectkey =~ s/\)/_/g;
	$projectkey =~ s/\@/_/g;
	$projectkey =~ s/\$/_/g;
} else {
  print "Bailing--No project name detected.  Please supply a project name\n";
  exit 1;
}
set_project();
close(OUTFILE);

sub set_project {
    my $projectkey = $ARGV[0];

   # Create Project
   #  /rest/api/1.0/projects/{projectKey}
   $client->PUT(
       '/rest/api/1.0/projects/' . $projectkey,
       $headers
   );
   print 'PUT https://bitbucket001.prod-iad.gs.nsgbu.internal/rest/api/1.0/projects/' . $projectkey . "\n";
   if( $client->responseCode() eq '200' ){
       print '-- Creating Project ' . $projectkey . "\n";
       print OUTFILE '-- Creating Project ' . $projectkey . "\n";
   } else {
       print 'Failed to create ' . $projectkey . "\n";
       print OUTFILE 'Failed to create ' . $projectkey . "\n";
       print "Error: Return code is : " . $client->responseCode() . "\n";
       foreach ( $client->responseHeaders() ) {
           print 'Header: ' . $_ . '=' . $client->responseHeader($_) . "\n";
       }
       print Dumper($client->responseContent());
   }
   sleep 2;
}
