#!/bin/ksh

SCRIPT_DIR=$(dirname "$0")
source "${SCRIPT_DIR}/bitbucket.utils.sh"
source "/etc/profile.d/path.sh"

if [[ -d $ORACLE_HOME ]]
   then
   echo $ORACLE_HOME
else
   bail "Cannot determine ORACLE_HOME value.  ORACLE_HOME should be populated from /etc/profile.d/path.sh"
fi

export  PATH=$ORACLE_HOME/bin:/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/X11R6/bin:/opt/netledger/common/bin:/opt/netledger/common/dlls:/opt/jdk/bin:/opt/apache/bin:/opt/oracle/bin:$ORACLE_HOME/bin:/opt/Oracle/JRE/bin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export ORACLE_SID=nlcdb
BACKUP_DIR=${1:-""}
if [[ ! -n $BACKUP_DIR ]]
   then
   echo "You MUST pass in a directory of where to store the backup"
   exit -1 
fi

UUID=${2:-""}

if [[ ! -n $UUID ]]
   then
   echo -n "generating UUID for you"
   UUID=`/usr/bin/uuidgen`
fi
echo "backup identifier is: $UUID"

DIR="${BACKUP_DIR}/${UUID}"

mkdir -p $DIR

if [[ -d $DIR ]]
   then
   echo "storing backups in $DIR"
else
   echo "unable to create $DIR"
   exit -1
fi


echo "starting backup"

 rman target / << EOF
 crosscheck archivelog all;
 CONFIGURE DEFAULT DEVICE TYPE TO DISK;
 CONFIGURE CONTROLFILE AUTOBACKUP OFF;
 CONFIGURE MAXSETSIZE TO 32G;
 CONFIGURE DEVICE TYPE DISK CLEAR;
 CONFIGURE CHANNEL DEVICE TYPE 'SBT_TAPE' CLEAR;
 CONFIGURE CHANNEL DEVICE TYPE DISK CLEAR;
 CONFIGURE COMPRESSION ALGORITHM 'MEDIUM' AS OF RELEASE 'DEFAULT' OPTIMIZE FOR LOAD TRUE;
 CONFIGURE RETENTION POLICY TO REDUNDANCY 1;
 RUN {
    ALLOCATE CHANNEL C1 DEVICE TYPE DISK FORMAT  '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C2 DEVICE TYPE DISK FORMAT  '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C3 DEVICE TYPE DISK FORMAT  '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C4 DEVICE TYPE DISK FORMAT  '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C5 DEVICE TYPE DISK FORMAT  '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C6 DEVICE TYPE DISK FORMAT  '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C7 DEVICE TYPE DISK FORMAT  '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C8 DEVICE TYPE DISK FORMAT  '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C9 DEVICE TYPE DISK FORMAT  '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C10 DEVICE TYPE DISK FORMAT '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C11 DEVICE TYPE DISK FORMAT '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C12 DEVICE TYPE DISK FORMAT '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C13 DEVICE TYPE DISK FORMAT '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C14 DEVICE TYPE DISK FORMAT '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C15 DEVICE TYPE DISK FORMAT '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    ALLOCATE CHANNEL C16 DEVICE TYPE DISK FORMAT '${DIR}/%d_%I_%u_%s_%p_bb_backup';
    BACKUP AS COMPRESSED BACKUPSET DATABASE TAG ='bb_backup' PLUS ARCHIVELOG;
    BACKUP CURRENT CONTROLFILE FORMAT '${DIR}/%d_cf_auto_bb_backup_%I_%u' TAG ='bb_backup';
    BACKUP SPFILE FORMAT              '${DIR}/%d_spfile_bb_backup_%I_%u' TAG ='bb_backup';
 }
 LIST BACKUP;
 EXIT;
 EOF
