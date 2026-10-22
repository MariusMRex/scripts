#!/usr/bin/env perl

use strict;
use warnings;
use MIME::Base64;
use REST::Client;
use JSON;
use Data::Dumper;
 
# Set the request parameters
my $host = 'https://rvbdlicense01:8100';
my $user = 'admin';
my $pwd = '[Redacted]';
my $response;
 
my $client = REST::Client->new(host => $host);
 
my $encoded_auth = encode_base64("$user:$pwd", '');
 
# Get the incident with sys_id declared above
$client->GET("/api/tmcm/1.3/bandwidth_pack_license_key/VXTPN000E9E29-20d16c85508bc71651f3ed4f90fdcee9",
             {'Authorization' => "Basic $encoded_auth",
              'Accept' => 'application/json'});
 
#print 'Response: ' . from_json($client->responseContent()) . "\n";
$response = from_json($client->responseContent());
print Dumper($response);
print "\n\n";
print 'Response status: ' . $client->responseCode() . "\n";
#foreach ( $client->responseHeaders() ) {
#  print 'Header: ' . $_ . '=' . $client->responseHeader($_) . "\n";
#}
