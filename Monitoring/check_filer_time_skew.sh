# This was from Venda.  It is full of useful bits: timestamps, nagios passive checks, remote netapp commands, submitting check to nagios

#!/bin/bash

# Global Vars
NAGIOS_URL="https://infra01.dc-1.uk.venda.com/cgi-bin/nagios3/cmd.cgi"
NAGIOS_USER=nagiosfilercheck
NAGIOS_PASS="[Redacted]"

# Local Time of *nix Host
LOCAL_HOST_TIME=`/bin/date +%s`

# What hosts need to have this
for host in filer01 filer02 r200-01; do

# Local Time of NetApp
FILER_TIME=`sudo ssh root@$host date |awk '{print $1,$2,$3,$4}'`

# Convert Human Time to Unix Epoch Time
FILER_UNIX_TIME=`date +%s -d"$FILER_TIME"`

# Time Difference between Local Host & Filer
#TIME_DIFF=$(($FILER_UNIX_TIME - $LOCAL_HOST_TIME))
TIME_DIFF=$(($LOCAL_HOST_TIME - $FILER_UNIX_TIME))

# Nagios Alert
if [ $TIME_DIFF -gt 60 ]
then
    status=2
else
    status=0
fi

# Submit Command to Nagios
curl -k --user $NAGIOS_USER:$NAGIOS_PASS "$NAGIOS_URL?cmd_typ=30&cmd_mod=2&host=$host&service=Time+Status+Skew&plugin_state=$status&plugin_output=Time+is+skew+by%3A+$TIME_DIFF+second%28s%29&perform
ance_data=&btnSubmit=Commit"

done
