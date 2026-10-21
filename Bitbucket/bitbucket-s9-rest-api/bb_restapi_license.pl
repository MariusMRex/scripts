#!/usr/bin/perl

use strict;
use warnings;
# Adapted from https://developer.atlassian.com/server/fisheye-crucible/writing-a-rest-client-in-perl/
use REST::Client;
#=================================================================================================================================================================================================================
# Package                                                       Arch                                       Version                                          Repository                                        Size
#=================================================================================================================================================================================================================
#Installing:
# perl-REST-Client                                              noarch                                     271-1.el6                                        applications                                      13 k
Installing for dependencies:
# perl-Crypt-SSLeay                                             x86_64                                     0.57-17.el6                                      oel-base                                          57 k
# perl-XML-LibXML                                               x86_64                                     1:1.70-5.el6                                     oel-base                                         364 k
# perl-XML-NamespaceSupport                                     noarch                                     1.10-3.el6                                       oel-base                                          16 k
# perl-XML-SAX                                                  noarch                                     0.96-7.el6                                       oel-base                                          77 k
#
#Transaction Summary
#=================================================================================================================================================================================================================
#Install       5 Package(s)
use JSON;
# Data::Dumper makes it easy to see what the JSON returned actually looks like 
# when converted into Perl data structures.
use Data::Dumper;
use Term::ReadKey;
use MIME::Base64;
#my $query_limit = '&limit=300';  # Max number of records to return from a API query

# Lets get some date information set
#(my $SEC, my $MIN, my $HOUR, my $MDAY, my $MON, my $YEAR, my $WDAY, my $YDAY, my $ISDST) = localtime(time);
## Some corrections for Date
#$YEAR = $YEAR + 1900;    		# Correct Year output, it is 'off' by 1900 normally
#$MON = $MON + 1;     			# Normally months go from 0-11, I want 1-12
## Pad certain date fields if they are too short.
#if(length($MON) == "1") {
#	    $MON = "0$MON";
#}
#if(length($MDAY) == "1") {
#	    $MDAY = "0$MDAY";
#}
#if(length($HOUR) == "1") {
#	    $HOUR = "0$HOUR";
#}
#if(length($MIN) == "1") {
#	    $MIN = "0$MIN";
#}
#if(length($SEC) == "1") {
#	    $SEC = "0$SEC";
#}
#my $date = "$YEAR-$MON-$MDAY";
my $outfile = '/var/tmp/bitbucket_license_expiration.txt';
my $mode = $ARGV[0];
my $days_left;

# Check to see if we are running in license update mode
if(length($mode)) {
	if($mode eq 'update') {
		$mode = 'UPDATE';
		grab_license_update();
		#update_outfile();
        } else {
                print "Error: unrecognized augment: $mode\n";
		print "If $0 is run without an augment it will simply decrement the monitoring file.\n"; 
		print "If $0 is run with the augment 'update' the license will be verified with a call to bitbucket\n";
                print "Unrecognized augments produce this help text.  Please try again.\n";
		exit 1;
 	}       
} else {
	$mode = 'cron';
	update_outfile();
}

####
## Just subroutines below this line
####

sub update_outfile {
	print "Reading in $outfile\n";
	open my $status_file, '<', "$outfile" or die "Can't open file $!";
	$days_left = do { local $/; <$status_file> };
        chomp($days_left);
	if($days_left =~ /^\d+\z/) {
                print "Original value found: $days_left\n";
		--$days_left;
                print "New value found: $days_left\n";
	} else {
                print "Cannot parse output: $days_left\n";
		print "Please have an bitbucket administrator run this script with the 'update' augment to re-populate the correct value.";
		$days_left = 'UNKNOWN';
	}
	close(LICENSE_STATUS);

	print "Updating $outfile\n";
	open(LICENSE_UPDATE, ">$outfile");
	print LICENSE_UPDATE "$days_left\n";
	close(LICENSE_UPDATE);
}

#sub rest_setup {
#	# Custom library for centralized auth
#	# ~/perl5/lib/perl5/BB_REST_AUTH.pm
#	#use BB_REST_AUTH;
#	#
#	#my $username = $ad_username;
#	#my $password = $ad_password;
#
#	print "Running in update mode.  Please provide credentials.\nUsername: ";
#	$username = <STDIN>;
#	chomp($username);
#	print 'Password: ';
#	$password = <STDIN>;
#	chomp($password);
#	my $headers = {Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
#	my $client = REST::Client->new();
#	$client->setHost('https://nacl-c001.adm.svale.netledger.com');
#	# add a CA to verify server certificates
#	$client->setCa('/usr/local/etc/openssl/cert.pem');
#}
	
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
sub grab_license_update {
	print "Running in update mode.  Please provide credentials. (Terminal will not echo user/pass input.)\nUsername: ";
        ReadMode( "noecho");
        chomp (my $username = <STDIN>);
	print "\nPassword: ";
        chomp (my $password = <STDIN>);
        print "\n";
        ReadMode ("original") ;
	my $headers = {Accept => 'application/json', Authorization => 'Basic ' . encode_base64($username . ':' . $password)};
	my $client = REST::Client->new();
	$client->setHost('https://nacl-c001.adm.svale.netledger.com');
	# add a CA to verify server certificates
	$client->setCa('/usr/local/etc/openssl/cert.pem');
	$client->GET(
		'/rest/api/1.0/admin/license',
		$headers
	);
	open(LICENSE_STATUS, ">$outfile");
	my $license = from_json($client->responseContent());
        # print Dumper $license;
        # Just pick values directly from JSON, without multiple responses the normal array processing is not needed.
        if($license->{expiryDate}) {
		my $expiry_milliseconds = $license->{expiryDate};
		if($expiry_milliseconds =~ /^\d+\z/) {
			# Fun fact: Bitbucket counts epoc time in milliseconds, not seconds
			# Not that such precision is needed for license data...
			# So convert milliseconds to seconds
			my $expiry_date = $expiry_milliseconds/1000;
			my $time = time();
			if($expiry_date > $time) {
			    print "License has not expired yet.\n";
			    print "Right now: $time < $expiry_date\n";
			    my $time_left = $expiry_date - $time;
			    # sprintf is used to round the number 
			    # A day in 86400 seconds long
			    $days_left = sprintf("%.0f", $time_left/86400);
			    print "Days Left: $days_left\n";
			} else {
			    print "License has expired!\n";
			    print "Right now: $time > $expiry_date\n";
			}
		} else {
			print "License data not a integer, so I am not sure how to parse it.  Exiting...\n";
			exit 1;
		}
	    } else {
		print "License Expiry data cannot be located!  Exiting...\n";
		exit 1;
	    }
	    print LICENSE_STATUS "$days_left\n";
    close(LICENSE_STATUS);
}
