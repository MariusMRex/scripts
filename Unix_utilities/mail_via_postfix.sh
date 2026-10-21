#!/bin/sh

#/mnt/admin/bin/venda_code_updater.sh complains that 'mail is not available, when
# postfix is available.  Let us just email through postfix

# Bogus data that would normally be provided in venda_code_updater.sh
DC_IS=LO6
OLDCODEINST=venda_code_five
NEWCODEINST=venda_code_zillion
FROM=MARIUS.REX.KING@oracle.com
TO=mrex@netsuite.com
NS_TASK=Issue1
SITE_LIST=all_sites
START_TIME=$(/bin/date "+%R")

#mail -s "[Code-Upgrade] $DC_IS :: CODE UPGRADE $NEWCODEINST" Venda-code-upgrade@netsuite.com -- -f $FROM <<EOF
/bin/cat << EOF | /usr/sbin/sendmail  -t
From: ${FROM}
To: Venda-code-upgrade@netsuite.com
Subject: [Code-Upgrade] ${DC_IS} :: CODE UPGRADE ${NEWCODEINST}


Process Documentation:
http://docs.uk.venda.com/vendadocs/CodeUpdateHowTo

NS Task:
$NS_TASK

Previous Code Version:
$OLDCODEINST

Destination Code Version:
$NEWCODEINST

Clients Migrated:
$SITE_LIST

Holding Page was not used for this Patch/Rollback

Code Upgrade Time:
Started – $START_TIME GMT
Finished – $(/bin/date "+%R") GMT
EOF
