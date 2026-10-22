#!/bin/bash
# When run on the salt masters, this script should be executed as the 'gitdeploy' user, as that is who owns the repos in salt roots

export ROOT=/data/servers/salt/roots                                  # Where is the salt roots
export DIRS=`/usr/bin/find ${ROOT} -maxdepth 1 -mindepth 1 -type d`   # Find all repos listed in salt roots
export PATH="/usr/bin/"                                               # All executables are in this path, so trust only this path

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
             git remote -v ;echo 'Hit enter to change to bitbucket002';read; git remote -v set-url `git remote -v  | grep fetch  | sed 's/bitbucket001/bitbucket002/' | awk '{print $1,$2}'`; echo 'Please verify the remotes now'; git remote -v
             ;;
        n|N) echo "Okay, skipping ${repository}"
             ;;
        *)   echo "Input not understood. Enter either Y or N"
             exit -1
             ;;
      esac
   done
