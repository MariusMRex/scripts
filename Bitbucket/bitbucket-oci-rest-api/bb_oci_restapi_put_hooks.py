#!/usr/local/bin/python3
'''
For whatever reason I cannot get perl's rest_client to perform
successful PUT requests to OCI bitbucket. It may be a library
problem.  So trying python instead.

This is my first attempt at a python REST API script
'''
import json
#import sys
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
HOOK_LOG = open('/Users/mrex/Documents/SE/CCS/bitbucket/api-data/hooks_by_repo_latest', 'r')
REGEX = re.compile(r'.*\s(\w+):(\w+.*).*\s--\s.*\(hook\skey\s\=\s(.*)\)')

# Define my functions
def test_forcepush_repo():
    '''
    This is a POC function. (Which is functional)
    No augments required.
    '''
    api_url = '{0}projects/sal/repos/legacy_ns_admin_scripts/settings/hooks/com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook/enabled'.format(API_URL_BASE)
    response = requests.put(api_url, headers=HEADERS, verify=CA_CERT)

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
        print('Updating hook')
        return json.loads(response.content.decode('utf-8'))
    else:
        print('[?] Unexpected Error: [HTTP {0}]: Content: {1}'.format(response.status_code, response.content))

def rest_put(api_url):
    '''This function actually makes the rest API push once supplied the api URL
    Put request for hooks:
    /rest/api/1.0/projects/{projectKey}/repos/{repositorySlug}/settings/hooks/{hookKey}/enabled
    '''
    # Throttle api calls
    time.sleep(10)

    response = requests.put(api_url, headers=HEADERS, verify=CA_CERT)

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
        print('--Hook updated')
        return json.loads(response.content.decode('utf-8'))
    else:
        print('[?] Unexpected Error: [HTTP {0}]: Content: {1}'.format(response.status_code, response.content))


def reject_forcepush_repo():
    '''
    Enable forcepush hook by parsing latest hooks log
    '''
    hook_key = 'com.atlassian.bitbucket.server.bitbucket-bundled-hooks:force-push-hook'
    hook = 'UNDEFINED'
    for hook_log_line in HOOK_LOG:
        match = REGEX.match(hook_log_line)
        if match:
            project = match.group(1)
            repo = match.group(2)
            hook = match.group(3)
        if hook == hook_key:
            api_url = '{0}projects/{1}/repos/{2}/settings/hooks/{3}/enabled'.format(API_URL_BASE, project, repo, hook)
            print('Updating Reject Force Push hook for {0}:{1}'.format(project, repo))
            rest_put(api_url)

def enable_min_approvals():
    '''
    This will need some sort of config to specify minimum approval number.
    '''

def enable_no_incomplete_tasks():
    '''Enable no-incomplete_tasks hook by parsing latest hooks log'''
    hook_key = 'com.atlassian.bitbucket.server.bitbucket-bundled-hooks:incomplete-tasks-merge-check'
    hook = 'UNDEFINED'
    for hook_log_line in HOOK_LOG:
        match = REGEX.match(hook_log_line)
        if match:
            project = match.group(1)
            repo = match.group(2)
            hook = match.group(3)
        if hook == hook_key:
            api_url = '{0}projects/{1}/repos/{2}/settings/hooks/{3}/enabled'.format(API_URL_BASE, project, repo, hook)
            print('Updating No incomplete taks hook for {0}:{1}'.format(project, repo))
            rest_put(api_url)

def enforce_gpg_sigs():
    '''
    Require GPG signatures for all commits
    This should be done on the project level (Need api path)
    but disabled for neteng
    '''

def enable_min_builds():
    '''
    This will need some sort of config to specify minimum builds
    This only applies to TOOL:mafia TOOL:Release Deploy Utils as far as I can tell
    '''

def enable_code_owners():
    '''
    This will need some sort of config to specify minimum approvals
    This only applies to SDDC:provisioning-environment-definitions
    '''

# Actually reference functions and do some work

# In case I ever do not need to read in logs, I could make it variable
#if len(sys.argv) < 2:
#    if sys.argv[0] == 'read':
#        READ_LOG = True

#reject_forcepush_repo()
#enable_no_incomplete_tasks()
