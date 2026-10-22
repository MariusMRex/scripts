#!/usr/bin/python
'''
This script aims to update the git configuration files for saltmaster and saltkickstart hosts.
This script is being written in support of the OCI bitbucket migration of 2020.

This script is based on update_all_repositories.sh.  The goal is to update the repository
sources for all git repositories the the script touches.
'''

from __future__ import print_function
import os
from os import path

PATH = '/data/servers/salt/roots'
FILE_NOT_FOUND = []
# While this worked, It tuned out I could skip it by simply testing of the file existed.
# This avoids occational salt time-outs, and only updates files that exist.
GRAB_SERVER_ROLE = os.popen('/usr/bin/sudo /usr/bin/salt-call --out=newline_values_only grains.get server_role')
SERVER_ROLE = GRAB_SERVER_ROLE.read()
SERVER_ROLE = SERVER_ROLE.strip()

def replace_remote(repo_config):
    ''' Read in git repo config and write out a copy with an updated remote url '''
    if path.isfile(repo_config):
        file_in = open(repo_config, "rt")
        data = file_in.read()
        data = data.replace('nacl-c001.adm', 'nacl-c002.adm')
        data = data.replace('bitbucket.adm', 'nacl-c002.adm')
        data = data.replace('2222', '7999/bitbucket001')
        file_in.close()
        #print(repo_config + ':')
        #print(data)
        file_out = open(repo_config, "wt")
        file_out.write(data)
        file_out.close()
    else:
        FILE_NOT_FOUND.append(repo_config)

for branch in ['production',
               'pre-production',
               'master'
              ]:
    for project in ['salt_pillars',
                    'salt_states',
                    'salt_firstboot',
                    'salt_grains',
                    'protected_salt_pillars',
                    'protected_salt_states',
                    'salt_reactors',
                    'ns_scripts'
                   ]:
        repo_config_file = PATH + '/' + branch + '/' + project + '/.git/config'
        replace_remote(repo_config_file)

for branch in ['production',
               'pre-production',
               'master'
              ]:
    for project in ['srecode']:
        repo_config_file = PATH + '/' + branch + '/' + project + '/.git/config'
        replace_remote(repo_config_file)

for branch in ['master']:
    for project in ['configuration_data']:
        repo_config_file = PATH + '/' + branch + '/' + project + '/.git/config'
        replace_remote(repo_config_file)

for branch in ['production']:
    for project in ['icinga_remote_plugins_ng']:
        repo_config_file = PATH + '/' + branch + '/' + project + '/.git/config'
        replace_remote(repo_config_file)

if SERVER_ROLE in ['saltkickstart']:
    GIT_CONFIG = '/data/servers/kickstart/.git/config'
    replace_remote(GIT_CONFIG)

for branch in ['production',
               'pre-production',
               'master'
              ]:
    for project in ['database']:
        repo_config_file = PATH + '/' + branch + '/' + project + '/.git/config'
        replace_remote(repo_config_file)

for branch in ['development']:
    for project in ['salt_pillars',
                    'salt_states',
                    'protected_salt_pillars',
                    'salt_firstboot'
                   ]:
        repo_config_file = PATH + '/' + branch + '/' + project + '/.git/config'
        replace_remote(repo_config_file)

for branch in ['development']:
    for project in ['configuration_data']:
        repo_config_file = PATH + '/' + branch + '/' + project + '/.git/config'
        replace_remote(repo_config_file)

print("Files not Found:")
if FILE_NOT_FOUND:
    for file_name in FILE_NOT_FOUND:
        print(file_name)
else:
    print("None")

# vim: set filetype=python sts=4 ts=4 sw=4 tw=0 colorcolumn=100 et :
