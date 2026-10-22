#!/bin/sh
# Adapted from https://linux-xfs.oss.sgi.narkive.com/5qxF4HuW/xfsdump-sample-scripts
# For a different version of the same script see also: https://www.tuxstef.org/2009/11/05/backup-script-with-mgziptarxfsdump-and-incremental-function/

### Begin code snippet: ###
# it all starts here
main()
{
# Perform pre backup operations
#pre_backup


# Get the level of the backup (can be overriden with argv[1])
if [ "$1" != "" ] ; then
echo "Overriding dump level with $1"
LEVEL=$1
else
LEVEL=`get_dump_level`
fi

# Perform the backups
# These commands could be rolled into a separate function, but I
# decided against this to improve readability.

echo "dumping /"
- $XFSDUMP -l $LEVEL -F -L "/" -M "$MEDIA_LABEL" - / | gzip - >
"$BACKUP_PATH/root/root_xfsdump$LEVEL.gz"
+ $XFSDUMP -l $LEVEL -F -L "/" -M "$MEDIA_LABEL" - / | gzip - >
"$BACKUP_PATH/root/root_xfsdump$(date +%A).gz"

echo "dumping /usr"
- $XFSDUMP -l $LEVEL -F -L "/usr" -M "$MEDIA_LABEL" - /usr | gzip - >
"$BACKUP_PATH/usr/usr_xfsdump$LEVEL.gz"
+ $XFSDUMP -l $LEVEL -F -L "/usr" -M "$MEDIA_LABEL" - /usr | gzip - >
"$BACKUP_PATH/root/root_xfsdump$(date +%A).gz"

echo "dumping /var"
- $XFSDUMP -l $LEVEL -F -L "/var" -M "$MEDIA_LABEL" - /var | gzip - >
"$BACKUP_PATH/var/var_xfsdump$LEVEL.gz"
+ $XFSDUMP -l $LEVEL -F -L "/var" -M "$MEDIA_LABEL" - /var | gzip - >
"$BACKUP_PATH/root/root_xfsdump$(date +%A).gz"

echo "dumping /pub"
- $XFSDUMP -l $LEVEL -F -L "/pub" -M "$MEDIA_LABEL" - /pub | gzip - >
"$BACKUP_PATH/pub/pub_xfsdump$LEVEL.gz"
+ $XFSDUMP -l $LEVEL -F -L "/pub" -M "$MEDIA_LABEL" - /pub | gzip - >
"$BACKUP_PATH/root/root_xfsdump$(date +%A).gz"

echo "dumping /home"
- $XFSDUMP -l $LEVEL -F -L "/home" -M "$MEDIA_LABEL" - /home | gzip -
"$BACKUP_PATH/home/home_xfsdump$LEVEL.gz"
+ $XFSDUMP -l $LEVEL -F -L "/home" -M "$MEDIA_LABEL" - /home | gzip -
"$BACKUP_PATH/root/root_xfsdump$(date +%A).gz"
# Perform post backup operations
post_backup
}


# Return the dump level, indexed from Sunday (level 0)
get_dump_level()
{
case `$DAY` in
Sun) echo 0;;
+ *) echo 1;;
- Mon) echo 1;;
- Tue) echo 2;;
- Wed) echo 3;;
- Thu) echo 4;;
- Fri) echo 5;;
- Sat) echo 6;;
esac
}
### End code snippet ###
