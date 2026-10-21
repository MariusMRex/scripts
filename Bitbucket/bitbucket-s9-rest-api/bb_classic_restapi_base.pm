package BB_REST_AUTH;

# I just want to centralize some variables in all my Bitbucket REST API scripts

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw[$ad_username $ad_password $ldap_username $ldap_password];
our $ad_username = 'mrex';
our $ad_password = 'W1nna()42';
our $ldap_username = 'mrex';
our $ldap_password = 'W1nna()5';

1;
