#!/usr/local/bin/python3
'''
For whatever reason I cannot get perl's rest_client to perform
successful PUT requests to OCI bitbucket. It may be a library
problem.  But python seems to work just fine

This is based off bb_oci_restapi_put_hooks.py
'''
import json
import time
import re
import requests

URL_BASE = 'https://bitbucket001.prod-iad.gs.nsgbu.internal'
API_URL_BASE = '{0}/rest/api/1.0/'.format(URL_BASE)
API_TOKEN = '[Redacted]'
HEADERS = {'Content-Type': 'application/json',
           'Authorization': 'Bearer {0}'.format(API_TOKEN)}
SALT_V2_ROOT = '/Users/mrex/GIT/SE/DOCKER/netsuite-configuration'
CA_CERT = '{0}/salt/shared/state/technology/bitbucket/files/SEAD_CA.crt'.format(SALT_V2_ROOT)
#READ_LOG = True
HOOK_LOG = open('/Users/mrex/Documents/SE/CCS/bitbucket/api-data/repo_perms_latest', 'r')
#REGEX = re.compile(r'(\w+),(\w)')

# Define my functions
def
