#!/bin/bash
 
export ROOT=/Volumes/git-case-sensitive/SE                                  # Where are git repos stored on this host?  Update this line as appropriate
#export ROOT=/Users/mrex/GIT/RANCHER                                        # Rancher/SDDC repos
export DIRS=`/usr/bin/find ${ROOT} -maxdepth 1 -mindepth 1 -type d`   # Find all repos included in the given root directory
 
for repository in ${DIRS}
   do
      cd ${repository}
      echo -e "#############"
      echo "Processing ${repository}"
      git remote -v ;echo 'Hit enter to change to bitbucket.nsgbu.netsuitecorp.com';read; git remote -v set-url `git remote -v  | grep fetch  | grep origin | sed 's/nacl-c002.adm.svale.netledger.com/bitbucket.nsgbu.netsuitecorp.com/' | awk '{print $1,$2}'`; echo 'Please verify the remotes now'; git remote -v
   done
