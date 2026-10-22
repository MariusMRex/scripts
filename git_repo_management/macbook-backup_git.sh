#!/bin/bash
# Modified from the script on git2.dc-1.uk.venda.com.  This obviously will not work in most other locations.

BASE=/Users/marius/git_base
DATE=`date +%Y-%m-%d`
FILE=$BASE/tmp/$DATE.git_backup_errors
echo $DATE > $FILE
echo "" >> $FILE

rsync -essh -av root@10.101.1.36:/home/git/ $BASE/home/git/

if [ $? = 0 ]
then
date +"%D %T: $BASE/home/git Successfully executed." >> $FILE
else
date +"%D %T: $BASE/home/git Unsuccessfully executed." >> $FILE
date +"%D %T:" >> $FILE
fi

rsync -essh -av root@10.101.1.36:/var/www/git/ $BASE/var/www/git/

if [ $? = 0 ]
then
date +"%D %T: $BASE/var/www/git Successfully executed." >> $FILE
else
date +"%D %T: $BASE/var/www/git Unsuccessfully executed." >> $FILE
date +"%D %T:" >> $FILE
fi

rsync -essh -av root@10.101.1.36:/etc/ssh/ $BASE/etc/ssh.git1

if [ $? = 0 ]
then
date +"%D %T: $BASE/etc/ssh Successfully executed." >> $FILE
else
date +"%D %T: $BASE/etc/ssh Unsuccessfully executed." >> $FILE
date +"%D %T:" >> $FILE
fi

echo "" >> $FILE
df >> $FILE

mv $FILE $BASE/var/log/gitbackup/
