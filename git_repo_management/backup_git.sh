#!/bin/bash
# Taken from git2.dc-1.uk.venda.com.  This obviously will not work in most other locations.

DATE=`date +%Y-%m-%d`
FILE=/tmp/$DATE.git_backup_errors
echo $DATE > $FILE
echo "" >> $FILE

rsync -essh -a 10.101.1.36:/home/git/ /home/git/

if [ $? = 0 ]
then
date +"%D %T: /home/git Successfully executed." >> $FILE
else
date +"%D %T: /home/git Unsuccessfully executed." >> $FILE
date +"%D %T:" >> $FILE
fi

rsync -essh -a 10.101.1.36:/var/www/git/ /var/www/git/

if [ $? = 0 ]
then
date +"%D %T: /var/www/git Successfully executed." >> $FILE
else
date +"%D %T: /var/www/git Unsuccessfully executed." >> $FILE
date +"%D %T:" >> $FILE
fi

rsync -essh -a 10.101.1.36:/etc/ssh/ /etc/ssh.git1

if [ $? = 0 ]
then
date +"%D %T: /etc/ssh Successfully executed." >> $FILE
else
date +"%D %T: /etc/ssh Unsuccessfully executed." >> $FILE
date +"%D %T:" >> $FILE
fi

echo "" >> $FILE
df >> $FILE

mv $FILE /var/log/gitbackup/
