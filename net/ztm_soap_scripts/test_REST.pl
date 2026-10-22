#!/usr/bin/env perl

use strict;
use warnings;
use MIME::Base64;
 
# http://search.cpan.org/~mcrawfor/REST-Client/lib/REST/Client.pm
# Example install using cpanm:
#   sudo cpanm -i REST::Client
use REST::Client;
 
# Set the request parameters
my $host = 'https://rvbdlicense01:8100';
my $user = 'admin';
my $pwd = '[Redacted]';
 
my $client = REST::Client->new(host => $host);
 
my $encoded_auth = encode_base64("$user:$pwd", '');
 
# Get the incident with sys_id declared above
$client->GET("/api/tmcm/1.3/license",
             {'Authorization' => "Basic $encoded_auth",
              'Accept' => 'application/json'});
 
print 'Response: ' . $client->responseContent() . "\n";
print 'Response status: ' . $client->responseCode() . "\n";
#foreach ( $client->responseHeaders() ) {
#  print 'Header: ' . $_ . '=' . $client->responseHeader($_) . "\n";
#}
