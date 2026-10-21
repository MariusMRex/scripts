#!/usr/local/bin/python3
'''
For whatever reason I cannot get perl's rest_client to perform
successful PUT requests to bitbucket. It may be a library
problem.  So trying python instead.

This script is related to SOURCE-414, password rotation for the amdin user
'''
import json
import sys
import requests

URL_BASE = 'https://nacl-c001.adm.svale.netledger.com'
API_URL_BASE = '{0}/rest/api/1.0/'.format(URL_BASE)
API_TOKEN = '[Redacted]'
HEADERS = {'Content-Type': 'application/json',
           'Authorization': 'Bearer {0}'.format(API_TOKEN)}
#SALT_V2_ROOT = '/Users/mrex/GIT/SE/DOCKER/netsuite-configuration'
#CA_CERT = '{0}/salt/shared/state/technology/bitbucket/files/SEAD_CA.crt'.format(SALT_V2_ROOT)
#PASSWORD_LOG = open('/Users/mrex/Documents/SE/CCS/bitbucket/api-data/update_classic_password_latest', 'r')

# Define my functions
def rest_put(api_url, credentials_json):
    '''
    This function actually makes the rest API push once supplied the api URL
    Put request for credentials: /rest/api/1.0/admin/users/credentials
    '''
    response = requests.put(api_url, headers=HEADERS, data=credentials_json)

    if response.status_code >= 500:
        print('[!] [{0}] Server Error'.format(response.status_code))
        return None
    elif response.status_code == 404:
        print('[!] [{0}] URL not found: [{1}]'.format(response.status_code, api_url))
        return None
    elif response.status_code == 401:
        print('[!] [{0}] Authentication Failed'.format(response.status_code))
        return None
    elif response.status_code == 400:
        print('[!] [{0}] Bad Request'.format(response.status_code))
        return None
    elif response.status_code >= 300:
        print('[!] [{0}] Unexpected Redirect'.format(response.status_code))
        return None
    elif response.status_code == 200:
        print('-- User record updated')
        return json.loads(response.content.decode('utf-8'))
    else:
        print('[?] Unexpected Error: [HTTP {0}]: Content: {1}'.format(response.status_code, response.content))


def update_user(username, password):
    '''
    Pass JSON object to the credentials URL to update a given user's password.
    /rest/api/1.0/admin/users/credentials
    '''

    api_url = '{0}admin/users/credentials'.format(API_URL_BASE)
    credentials = {"password": password, "passwordConfirm": password, "name": username}
    credentials_json = json.dumps(credentials)
    print('Updating password for user {0}'.format(username))
    print('JSON content: {0}'.format(credentials_json))
    rest_put(api_url, credentials_json)

# Actually reference functions and do some work
if len(sys.argv) == 3:
    #username = sys.argv[1]
    #password = sys.argv[2]
    update_user(sys.argv[1], sys.argv[2])
else:
    sys.exit('Please provide two augments, a username and a password')
