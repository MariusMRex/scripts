#!/bin/bash 

# This is not working quite right yet.  It prompts for passwords for every update.
#

#Update all directories for OCI
#set -x
RED='\033[0;31m'
NC='\033[0m'
YEL='\033[1;33m'
CYAN='\033[0;36m'
starting_dir=$(pwd)
git=$(which git)
base_dir="/Users/$(whoami)/GIT/RANCHER/"
#directories=("netsuite-configuration" "provisioning-environment-definitions" "rash" "rpm_manifest" "rundeck-jobs" "sddc-repo-manifests" "terraform-oci-modules")
directories=`find ~/GIT/RANCHER -maxdepth 3 -name .git -type d | rev | cut -c 6- | rev | cut -c 25-`
bad_dir=()
failed_status_check(){
        rc=$(${git} status -s | grep -c '^ M\|^ D')
        if [ ${rc} -ge 1 ] ; then
                true
        else
                false
        fi
}

for x in ${directories[@]}
do
        cd ${base_dir}${x}
        if failed_status_check ; then
                bad_dir[${#bad_dir[@]}]=$x
                continue
        fi
        echo -e "Updating ${x}"
        ${git} checkout develop
        ${git} pull
        ${git} checkout master
        ${git} pull
done
cd ${starting_dir}
if [ ${#bad_dir[@]} -ge 1 ] ; then
        echo -e "${YEL}Fix these directories: ${NC}"
        echo -e "${RED}${bad_dir[@]}${NC}"
fi
