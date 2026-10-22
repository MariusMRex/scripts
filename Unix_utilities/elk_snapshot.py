#! /opt/homebrew/bin/python3

# Script elk snapshot tasks
# In the long run I may want to run this remotely.

import sys
import subprocess
from settings import elk_user, elk_password

cURL = '/usr/bin/curl'
json_out = '/opt/homebrew/bin/jq'
cURL_method = 'GET'
API_command = '_snapshot/CSE_14783_oci_bucket_na_elkops/'
server = ''
index = ''
elk_fake = 'SuperSecureYo'

if len(sys.argv) == 3:
    server = sys.argv[1]
    index = sys.argv[2]
    print("Executing {0} -X{1} -u {2}:{3} 'https://{4}.netledger.com/ELKUSR/{5}{6}' | {7}".format(cURL, cURL_method, elk_user, elk_fake, server, API_command, index, json_out))
elif len(sys.argv) == 2:
    print("Too few Augments")
else:
    print("Please provide the server and index to check.  Example {0} elkapp.svale cspaudit".format(sys.argv[0]))
    print("If no augments are provided, this script will default to https://elkops.svale.netledger.com/ELKUSR/_cluster/health ")
    sys.exit(2)

#
command = "{0} -X{1} -u {2}:'{3}' 'https://{4}.netledger.com/ELKUSR/{5}{6}' | {7}".format(cURL, cURL_method, elk_user, elk_password, server, API_command, index, json_out)

#check = subprocess.Popen('{0}'.format(command), shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
check = subprocess.run('{0}'.format(command), capture_output=True, shell=True)
stdout, stderr = check.communicate()

if stderr:
        print("Connection failed")
else:
        print("Connected Sucessfully")
