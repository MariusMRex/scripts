#!/bin/bash

echo -n "This script will potentially cause serious damage if run on a system its not meant for. Are you sure? Y/N: "
read var
echo ""

case $var in
        y|Y) echo "Okay, continuing";;
        n|N) echo "Okay, not running"
             exit 1
             ;;
        *)   echo "Input not understood. Enter either Y or N"
             exit -1
             ;;
esac


export ORACLE_SID=nlcdb
ORACLE_UID="101"
SAMPLE_DIR="/opt/oracle/oradata/local"

# Try to grab some pillar values from Salt
echo "Fetching passwords from salt.  This may take a minute or two."
SYS_PASS=`/usr/bin/sudo /usr/bin/salt-call --out=newline_values_only pillar.get bitbucket_oracle_users:properties:sys_passwd`
BITBUCKET_PASS=`/usr/bin/sudo /usr/bin/salt-call --out=newline_values_only pillar.get bitbucket_oracle_users:properties:bitbucket_passwd`

# If pillar.get fails, fall back to user input
if [ -z "${SYS_PASS}" ]; then
   echo -n "Oracle password for sys_password user could not be fetched from pillar. This may indicate a problem with the build setup.  If you still wish to continue, please provide a password: "
   # Silently read in password (Do not echo input)
   read -s SYS_PASS
   echo ""
fi

if [ -z "${BITBUCKET_PASS}" ]; then
   echo -n "Oracle password for bitbucket user could not be fetched from pillar. This may indicate a problem with the build setup.  If you still wish to continue, please provide a password: "
   # Silently read in password (Do not echo input)
   read -s BITBUCKET_PASS
   echo ""
fi

## Some tests to verify some requirements are in place
##
# Is this script being run as the appropriate user?
if [[ ${EUID} -ne ${ORACLE_UID} ]]; then
   echo "I am NOT user oracle. Bailing execution."
   exit -1
fi

# Is Oracle's homedir writable by user oracle?
if [[ -w ${HOME} ]]; then
   echo "Verified that user can write to ${HOME}"
else
   echo "It looks like ${HOME} is not writable.  Aborting execution as DB creation would fail."
  exit -1
fi

# Is ORACLE_HOME set?
if [[ -d ${ORACLE_HOME} ]]; then
  echo "ORACLE_HOME set to ${ORACLE_HOME}"
else
  echo "The variable ORACLE_HOME could not be fetched from environment. Is the file /etc/profile.d/path.sh in the correct state?"
  echo "Script execution halted.  Investigate the environment setup before re-executing this script."
  exit -1
fi

# Check for a sample oracle directory we will need to verify salt setup is decently advanced
if [[ -d "${SAMPLE_DIR}" ]]; then
   echo "Verified existance of ${SAMPLE_DIR}."
else
   echo "Cannot locate ${SAMPLE_DIR}"
   echo "Bailing execution"
   echo "It may be necessary to run salt highstate again to prepare the system for running this script."
  exit -1
fi

# Can the template file be located?
if [[ -f "${ORACLE_HOME}/assistants/dbca/templates/General_Purpose.dbc" ]]; then
   echo "DB template found at ${ORACLE_HOME}/assistants/dbca/templates/General_Purpose.dbc"
else
   echo "Cannot locate template ${ORACLE_HOME}/assistants/dbca/templates/General_Purpose.dbc"
   echo "Is oracle DB properly installed?"
  exit -1
fi

echo "Building nlcdb:"
${ORACLE_HOME}/bin/dbca -silent -createDatabase -templateName General_Purpose.dbc -gdbname nlcdb -sid nlcdb -responseFile NO_VALUE -characterSet UTF8 -nationalCharacterSet UTF8 -sysPassword ${SYS_PASS} -systemPassword ${SYS_PASS} -createAsContainerDatabase true -numberOfPDBs 0 -pdbName nlpdb1 -pdbAdminPassword ${SYS_PASS} -databaseType MULTIPURPOSE -automaticMemoryManagement false -totalMemory 34963 -emConfiguration NONE

SEEDFILE=`find /opt/oracle/oradata/NLCDB/pdbseed -name "temp*" -print0`

# Can the seed file be located?
if [[ -f ${SEEDFILE} ]]; then
   echo "Found pdbseed file ${SEEDFILE}"
   echo "Using seed to create PDB BBUCKET"
else
   echo "Cannot locate pdb seedlife in /opt/oracle/oradata/NLCDB/pdbseed"
   echo "It looks like something went wrong with nlcdb creation. Aborting."
  exit -1
fi

sqlplus / as sysdba << EOF1
define seedfile = ${SEEDFILE}
CREATE PLUGGABLE DATABASE bbucket
ADMIN USER salesadm IDENTIFIED BY ${SYS_PASS} ROLES = (dba) DEFAULT TABLESPACE sales DATAFILE '/opt/oracle/oradata/local/bbucket_sales_01.dbf' SIZE 250M  AUTOEXTEND ON
FILE_NAME_CONVERT = ('/opt/oracle/oradata/NLCDB/pdbseed/system01.dbf','/opt/oracle/oradata/local/bbucket_system01.dbf',
  '/opt/oracle/oradata/NLCDB/pdbseed/sysaux01.dbf','/opt/oracle/oradata/local/bbucket_sysaux01.dbf',
  '/opt/oracle/oradata/NLCDB/pdbseed/undotbs01.dbf','/opt/oracle/oradata/local/bbucket_undotbs01.dbf',
  '&seedfile', '/opt/oracle/oradata/local/bbucket_temp01.dbf')
   STORAGE (MAXSIZE 2G) PATH_PREFIX = none STANDBYS=NONE;

ALTER PLUGGABLE DATABASE bbucket OPEN READ WRITE;
EXIT;
EOF1

# Set PDB SID
export ORACLE_PDB_SID=BBUCKET

echo "Creating bitbucket user"
sqlplus / as sysdba << EOF2

ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;

CREATE TABLESPACE USERS DATAFILE '/opt/oracle/oradata/local/users_01.dat' SIZE 100M AUTOEXTEND ON NEXT 100M MAXSIZE 10G;

CREATE USER bitbucket
IDENTIFIED BY ${BITBUCKET_PASS}
DEFAULT TABLESPACE USERS
QUOTA UNLIMITED ON USERS;
GRANT CONNECT, RESOURCE to bitbucket;

CREATE VIEW bitbucket.all_objects AS
SELECT *
FROM sys.all_objects
WHERE owner = upper('bitbucket');

EXIT;
EOF2

# Start up the listener
${ORACLE_HOME}/bin/lsnrctl start
