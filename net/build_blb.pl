#!/usr/bin/perl 
#===============================================================================
#
#         FILE: build_blb.pl
#
#        USAGE: ./build_blb.pl  $IP_INTERNAL $IP_EXTERNAL $IP_BGP $IP_MANAGEMENT 
#
#  DESCRIPTION: Configure networking for wt BLB servers.  NEVER TESTED - As I 
#				had to convert to /bin/sh
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Marius Rex (marius@venda.com)
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 10/23/2013 02:06:40 PM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

# Replicate Stingray_traffic_manager.ks features, since I cannot kickstart.

my $IP_INTERNAL = $ARGV[0];
my $IP_EXTERNAL = $ARGV[1];
my $IP_BGP = $ARGV[2];
my $IP_MANAGEMENT = $ARGV[3];
my $NET_SCRIPTS = "/etc/sysconfig/network-scripts";
my $ETH_NUM = '0';



##### Interfaces #####

# Internal bond0 = eth0-3
open(BOND0, ">$NET_SCRIPTS/ifcfg-bond0");
print BOND0 << "EOF";
DEVICE=bond0
TYPE=Ethernet
BOOTPROTO=static
IPADDR=$IP_INTERNAL
NETMASK=255.255.252.0
BROADCAST=10.8.3.255
ONBOOT=yes
BONDING_OPTS="mode=4 miimon=100 lacp_rate=1 xmit_hash_policy=1"
DELAY=0
EOF
close(BOND0);

while($ETH_NUM >= '3') {
	open(ETH, ">$NET_SCRIPTS/ifcfg-eth$ETH_NUM");
	print ETH << "EOF";
DEVICE="eth$ETH_NUM"
MASTER=bond0
TYPE=Ethernet
SLAVE=yes
NM_CONTROLLED="no"
ONBOOT=yes
BOOTPROTO=none
IPV6INIT=no
EOF

	close(ETH);
	++$ETH_NUM;
}

# External bond1 = eth4-7
open(BOND1, ">$NET_SCRIPTS/ifcfg-bond1");
print BOND1 << "EOF";
DEVICE=bond1
TYPE=Ethernet
BOOTPROTO=static
IPADDR=$IP_EXTERNAL
NETMASK=255.255.252.0
BROADCAST=212.25.235.255
ONBOOT=yes
BONDING_OPTS="mode=4 miimon=100 lacp_rate=1 xmit_hash_policy=1"
DELAY=0
EOF
close(BOND1);

while($ETH_NUM >= '7') {
	open(ETH, ">$NET_SCRIPTS/ifcfg-eth$ETH_NUM");
	print ETH << "EOF";
DEVICE="eth$ETH_NUM"
MASTER=bond1
TYPE=Ethernet
SLAVE=yes
NM_CONTROLLED="no"
ONBOOT=yes
BOOTPROTO=none
IPV6INIT=no
EOF

	close(ETH);
	++$ETH_NUM;
}

# BGP Uplink bond2 = eth10-11
open(BOND2, ">$NET_SCRIPTS/ifcfg-bond2");
print BOND2 << "EOF";
DEVICE=bond2
TYPE=Ethernet
BOOTPROTO=static
IPADDR=$IP_BGP
NETMASK=255.255.248.0
BROADCAST=212.25.247.255
ONBOOT=yes
BONDING_OPTS="mode=4 miimon=100 lacp_rate=1 xmit_hash_policy=1"
DELAY=0
EOF
close(BOND2);

$ETH_NUM = "10";
while($ETH_NUM >= '11') {
	open(ETH, ">$NET_SCRIPTS/ifcfg-eth$ETH_NUM");
	print ETH << "EOF";
DEVICE="eth$ETH_NUM"
MASTER=bond2
TYPE=Ethernet
SLAVE=yes
NM_CONTROLLED="no"
ONBOOT=yes
BOOTPROTO=none
IPV6INIT=no
EOF

	close(ETH);
	++$ETH_NUM;
}

# Management bond3 = eth8-9
open(BOND3, ">$NET_SCRIPTS/ifcfg-bond3");
print BOND3 << "EOF";
DEVICE=bond3
TYPE=Ethernet
BOOTPROTO=static
IPADDR=$IP_BGP
NETMASK=255.255.248.0
BROADCAST=212.25.247.255
ONBOOT=yes
BONDING_OPTS="mode=4 miimon=100 lacp_rate=1 xmit_hash_policy=1"
DELAY=0
EOF
close(BOND3);

$ETH_NUM = "8";
while($ETH_NUM >= '9') {
	open(ETH, ">$NET_SCRIPTS/ifcfg-eth$ETH_NUM");
	print ETH << "EOF";
DEVICE="eth$ETH_NUM"
MASTER=bond3
TYPE=Ethernet
SLAVE=yes
NM_CONTROLLED="no"
ONBOOT=yes
BOOTPROTO=none
IPV6INIT=no
EOF

	close(ETH);
	++$ETH_NUM;
}

# Clean up ownership and perms
system("/bin/chown root:root $NET_SCRIPTS/ifcfg-*");
system("/bin/chmod 744 $NET_SCRIPTS/ifcfg-*") 

##### END Interfaces #####


##### BEGIN Routes #####

open(ROUTEB0, ">$NET_SCRIPTS/route-bond0");
print ROUTEB0 << "EOF";
10.0.38.105 via 10.8.0.1 dev bond0 
10.0.38.104 via 10.8.0.1 dev bond0 
10.0.38.103 via 10.8.0.1 dev bond0 
10.0.38.102 via 10.8.0.1 dev bond0 
10.0.38.101 via 10.8.0.1 dev bond0 
10.0.0.41 via 10.8.0.1 dev bond0 
10.0.0.42 via 10.8.0.1 dev bond0 
10.0.0.43 via 10.8.0.1 dev bond0 
10.0.13.0/24 via 10.8.0.1 dev bond0 
10.0.10.0/24 via 10.8.0.1 dev bond0 
10.8.128.0/22 via 10.8.0.1 dev bond0 
10.8.140.10/32 via 10.8.0.1 dev bond0
10.8.140.11/32 via 10.8.0.1 dev bond0
10.0.57.0/24 via 10.8.1.1 dev bond0 
10.0.58.0/24 via 10.8.1.1 dev bond0
EOF
close(ROUTEB0);

open(ROUTEB1, ">$NET_SCRIPTS/route-bond1");
print ROUTEB1 << "EOF";
10.128.80.222 via 212.25.234.1 dev bond1
10.130.0.112/28 via 212.25.234.1 dev bond1
10.65.73.0/24 via 212.25.234.1 dev bond1
10.240.7.0/24 via 212.25.234.1 dev bond1
10.65.76.0/22 via 212.25.234.1 dev bond1
10.8.192.0/22 via 212.25.234.1 dev bond1
10.45.76.0/22 via 212.25.234.1 dev bond1
EOF
close(ROUTEB1);

open(ROUTEB3, ">$NET_SCRIPTS/route-bond3");
print ROUTEB3 << "EOF";
10.0.0.0/8 via 10.8.4.1 dev eth4
EOF
close(ROUTEB3);

# Clean up ownership and perms
system("/bin/chown root:root $NET_SCRIPTS/route*");
system("/bin/chmod 744 $NET_SCRIPTS/route-*") 

##### END Routes #####

# Let us assume cfengine will set the root passwd


##### BEGIN IPTABLES #####
open(IPTABLES, ">/etc/sysconfig/iptables");
print IPTABLES << "EOF"
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
COMMIT
EOF
close(IPTABLES);

# Clean up ownership and perms
system("/bin/chown root:root /etc/sysconfig/iptables");
system("/bin/chmod 744 /etc/sysconfig/iptables");

##### END IPTABLES #####
