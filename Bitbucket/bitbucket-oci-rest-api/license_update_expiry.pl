#!/usr/bin/perl
# This script was originally written to to service https://jira.svale.netledger.com/jira/browse/MD-3402
# This script is part of the license update procedures currently documented here on Confluence:
#    https://confluence.corp.netsuite.com/display/EOA/Update+Bitbucket+Licenses

use strict;
use warnings;
# Adapted from https://developer.atlassian.com/server/fisheye-crucible/writing-a-rest-client-in-perl/
use REST::Client;
use JSON;
# Data::Dumper makes it easy to see what the JSON returned actually looks like 
# when converted into Perl data structures.
use Data::Dumper;
use Term::ReadKey;
use MIME::Base64;

my $outfile = '/var/cache/node_exporter/bitbucket.prom';
my $bb_host = 'https://bitbucket.prod-phx.gs.nsgbu.netledger.com';
my $ca_cert = '/usr/local/etc/openssl/cert.pem';
my $expiry_date;

# Answer to API call looks like this:
# {
# "creationDate": 1627567200000,
#   "purchaseDate": 1627740000000,
#   "expiryDate": 1659276000000,
#   "numberOfDaysBeforeExpiry": 320,
#   "maintenanceExpiryDate": 1659276000000,
#   "numberOfDaysBeforeMaintenanceExpiry": 320,
#   "gracePeriodEndDate": 1659276000000,
#   "numberOfDaysBeforeGracePeriodExpiry": 320,
#   "maximumNumberOfUsers": 1000,
#   "unlimitedNumberOfUsers": false,
#   "serverId": null,
#   "supportEntitlementNumber": "SEN-18163439",
#   "license": "AAABkg0ODAoPeNp1kVuP0zAQhd/9KyzxAkKt7GRFs5UsEZKwDWqa3TZboWfpmZCTHOpbGch/HpyWy4P\r\nPE6OJ985Z15lRUs/tSV1bilfrV1nzTgNwow6zOHkgt0RtVFNLfg7xlbMc11Odm12Rp3mj6bXBteMkaCp\r\n/OxxoLtlMRLfNxpkiUvZVDO8X4YAf4taWN0iKac/b3pNJMH34GOIn7mze/JjZaHZ69W1u8PH\r\nPSSxrP3iIU8zv8zDL+e9Fx6Pbzc3xbfYM3l1ufNP4iTIoT0bqdXVDiWNgN5VT6uhlv+xP/nqA6hnnFbm\r\ntHEotnF4iHYL7vGVe+vekH4Q/3xI9VeolYGkl45hSaBxnP8qcbVw2Qw6WlBD+hxK8zv+y1kdEuIf/x+U\r\nPbfygpa+HmqjU29v6HBjOp77tKZBU1WopYKSZqgrpsn0AsAhROvTPrjsmmG9Tp\r\nV6/ObqfOM97a3AIUS9i1sPSI0VjXoMEskg8mP+yCuGg=X02jf",
#   "status": {
#     "currentNumberOfUsers": 573,
#     "serverId": "BSNW-O6SK-O5S0-E143"
#   }
# }
#
#
print "Please provide credentials that have administrative access to bitbucket\nUsername: ";
ReadMode( "noecho");
chomp (my $username = <STDIN>);
print "\nPassword: ";
chomp (my $password = <STDIN>);
print "\n";
ReadMode ("original") ;

# Query the Web API
my $headers = {Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
my $client = REST::Client->new();
$client->setHost("$bb_host");
# add a CA to verify server certificates
$client->setCa("$ca_cert");
$client->GET(
	'/rest/api/1.0/admin/license',
	$headers
);

# Parse the data
open(LICENSE_STATUS, ">$outfile");
my $license = from_json($client->responseContent());
# Just pick values directly from JSON, without multiple responses the normal array processing is not needed.
if($license->{expiryDate}) {
	my $expiry_milliseconds = $license->{expiryDate};
	if($expiry_milliseconds =~ /^\d+\z/) {
		# Fun fact: Bitbucket counts epoc time in milliseconds, not seconds
		# Not that such precision is needed for license data...
		# So convert milliseconds to seconds
		$expiry_date = $expiry_milliseconds/1000;
	} else {
		print "Fail: License expiry data does not seem to be a number.  Not sure how to proceed.\n This is what the server returned:\n";
		print Dumper $license;
		exit 1;
	}
	print LICENSE_STATUS "# HELP bitbucket_expiry_date_seconds License expiry date in seconds since the epoch.\n";
        print LICENSE_STATUS "# TYPE bitbucket_expiry_date_seconds gauge\n";
        print LICENSE_STATUS "bitbucket_expiry_date_seconds $expiry_date\n";
	print "Success: New license expiry data written to $outfile\n";
} else {
	print "Fail: License expiry data cannot be located!\nThis is what the server returned:\n";
	print Dumper $license;
	exit 1;
}
close(LICENSE_STATUS);
