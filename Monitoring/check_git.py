#!/usr/bin/python

'''
Note Bene: This is intended to run on python 2.6, and will likely fail on more recent versions of python.

Basic script to monitor availability of git from bitbucket. See: https://jira.svale.netledger.com/jira/browse/MD-3330
Variables:
    project: git project to access.  Example: sre
    repo: git repo to access.  Example: icinga_configuration_ng
    server: Server to access.  Example: bitbucket001.prod-phx.gs.nsgbu.internal
'''

import sys
import subprocess

user = 'git'
port = 7999
server = ''
project = ''
repo = ''
git_command = '/usr/bin/git'
protocol = 'ssh://'

if len(sys.argv) == 1:
        server = 'bitbucket001.prod-phx.gs.nsgbu.internal'
        project = 'sre'
        repo = 'icinga_configuration_ng'
        print("Checking {0} ls-remote {1}{2}@{3}:{4}/{5}/{6}.git".format(git_command, protocol, user, server, port, project, repo))
elif len(sys.argv) == 4:
        server = sys.argv[1]
        project = sys.argv[2]
        repo = sys.argv[3] 
        print("Checking {0} ls-remote {1}{2}@{3}:{4}/{5}/{6}.git".format(git_command, protocol, user, server, port, project, repo))
else:
        print("Please provide the server, project, and repo name to check.  Example {0} {1} {2} {3}".format(sys.argv[0], sys.argv[1], sys.argv[2], sys.argv[3]))
        print("If no augments are provided, this script will default to checking SRE:icinga_configuration_ng")
        sys.exit(2)

command = '{0} ls-remote {1}{2}@{3}:{4}/{5}/{6}.git'.format(git_command, protocol, user, server, port, project, repo)

check = subprocess.Popen('{0}'.format(command), shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
stdout, stderr = check.communicate()

if stderr:
        print("Connection failed")
else:
        print("Connected Sucessfully")
