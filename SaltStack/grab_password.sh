#!/bin/bash

echo 'start testing'
PASSWORD=`sudo /usr/bin/salt-call --out=newline_values_only pillar.get bitbucket_configuration:bitbucket_backup_package`

# This logic is smarter
# If password in not defined, or results in an empty string, prompt for it
if [ -z "${PASSWORD}" ]; then
  echo -n "Password not found.  Please provide a password: "
  # Silently read in password (Do not echo input)
  read -s PASSWORD
  echo ""
fi
echo "password is ${PASSWORD} dude!"
