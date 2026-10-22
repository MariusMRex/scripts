#!/bin/bash
# When run on the salt masters, this script should be executed as the 'gitdeploy' user, as that is who owns the repos in salt roots

ROOT=/data/servers/salt/roots                                  # Where is the salt roots
DIRS=`/usr/bin/find ${ROOT} -maxdepth 1 -mindepth 1 -type d`   # Find all repos listed in salt roots
GITDEPLOY_UID=602                                               # UID of the gitdeploy user
export PATH="/usr/bin/"                                               # All executables are in this path, so trust only this path

if [[ ${EUID} -ne ${GITDEPLOY_UID} ]]; then
   echo "I am NOT user gitdeploy. Bailing execution."
   exit -1
fi

if [[ $(hostname) = *prod-phx.gs.nsgbu.internal ]]; then
   OLD='bitbucket003.prod'
   NEW='bitbucket001.prod'
else
   OLD='bitbucket002.prod'
   NEW='bitbucket001.prod'
fi

for repository in ${DIRS}
   do
      cd ${repository}
      echo -e "\n\n#############"
      echo "Checking status of ${repository}."
      git status
      echo -n "Does this look OK? Y/N: "
      read var
      echo ""
      case $var in
        y|Y) echo "Okay, continuing tp process ${repository}" 
             git remote -v ;echo "Hit enter to change to ${NEW}";read; git remote -v set-url `git remote -v  | grep fetch  | sed "s/${OLD}/${NEW}/" | awk '{print $1,$2}'`; echo 'Please verify the remotes now'; git remote -v
             ;;
        n|N) echo "Okay, skipping ${repository}"
             ;;
        *)   echo "Input not understood. Enter either Y or N"
             exit -1
             ;;
      esac
   done
