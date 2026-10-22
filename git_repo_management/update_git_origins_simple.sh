#!/bin/bash
 
#export ROOT=/Volumes/git-case-sensitive/SE                                       # Where are git repos stored on this host?  Update this line as appropriate
export ROOT=/Volumes/git-case-sensitive/SE/DOCKER                                      # Where are git repos stored on this host?  Update this line as appropriate
export DIRS=`/usr/bin/find ${ROOT} -maxdepth 1 -mindepth 1 -type d`   # Find all repos included in the given root directory
 
for repository in ${DIRS}
   do
      cd ${repository}
      echo -e "#############"
      echo "Processing ${repository}"
      git remote -v ;echo 'Hit enter to change to nacl-c002.adm.svale.netledger.com';read; git remote -v set-url `git remote -v  | grep origin | grep fetch | sed 's/nacl-c001/nacl-c002/' | awk '{print $1,$2}'`; echo 'Please verify the remotes now'; git remote -v
   done
