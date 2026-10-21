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
export CONTROLFILE=${1:-""}

if [[ ! -n $CONTROLFILE ]]
   then
   echo "You MUST pass in the FULL path to the controlfile"
   exit -1
fi

if [[ ! -e $CONTROLFILE ]]
   then
   echo "You MUST pass in the FULL path to the controlfile and it MUST exist"
   exit -1
fi
export DBID=${2:-""}

if [[ ! -n $DBID ]]
   then
   echo -n "the databases DBID must be passed in"
   exit -1
fi
echo "DBID is: $DBID"
echo "Control file  is: $CONTROLFILE"

echo "starting restore"

sqlplus / as sysdba << EOF
SHUTDOWN ABORT
STARTUP NOMOUNT;
EXIT;
EOF

 rman target / << EOF
 SET DBID ${DBID};
 RUN {
   ALLOCATE CHANNEL c0 DEVICE TYPE DISK;
   ALLOCATE CHANNEL c1 DEVICE TYPE DISK;
   ALLOCATE CHANNEL c2 DEVICE TYPE DISK;
   ALLOCATE CHANNEL c3 DEVICE TYPE DISK;
   ALLOCATE CHANNEL c4 DEVICE TYPE DISK;
   ALLOCATE CHANNEL c5 DEVICE TYPE DISK;
   ALLOCATE CHANNEL c6 DEVICE TYPE DISK;
   ALLOCATE CHANNEL c7 DEVICE TYPE DISK;
   ALLOCATE CHANNEL c8 DEVICE TYPE DISK;
   ALLOCATE CHANNEL c9 DEVICE TYPE DISK;
   ALLOCATE CHANNEL c10 DEVICE TYPE DISK;
   RESTORE CONTROLFILE FROM '${CONTROLFILE}';
 sql 'ALTER DATABASE MOUNT';
   RESTORE DATABASE;
   RECOVER database;
 sql 'ALTER DATABASE OPEN RESETLOGS';
 sql 'ALTER PLUGGABLE DATABASE ALL OPEN';
}
 EXIT;
 EOF
