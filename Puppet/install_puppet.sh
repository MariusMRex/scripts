#!/bin/sh

# Install the RPM from yum repository
/bin/echo "#### Installing Puppet"
/usr/bin/yum -y install puppet
# Turn on Puppet service on client
/bin/echo "#### Enabling Puppet service"
/sbin/chkconfig --level 345 puppet on
# Point the cllent to repo server as the master
/bin/echo "#### Making repo the puppet master"
/usr/local/bin/perl -i -pe 's/\#PUPPET_SERVER=puppet/PUPPET_SERVER=repo/' /etc/sysconfig/puppet
# Start the service
/sbin/service puppet start
# Remind me to sign the client certificate
/bin/echo -e "Please run:\n puppetca --sign `/bin/hostname` on puppetmaster"



