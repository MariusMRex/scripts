/bin/rpm -ivh /nfsassets/RPM/epel-release-5-4.noarch.rpm
/usr/bin/yum update -y puppet facter
echo
sleep 1
echo
/usr/sbin/puppetd -o --server=repo.shermanstravel.com --test
echo 
echo "Restarting puppet in 5 seconds...If we need to abort, CTR-C now."
sleep 5
/sbin/service puppet restart
