#!/usr/local/bin/python3
'''
Quick script to find the yaml manifest files and parse them
version: 1

bitbucket hook in netsuite-configuration branch: HACKATHON-check-software-hook
backup copy in ~/Documents/SE/OCI/hackathon_2020/hook_parse_manifest_py.j2
'''
import glob
import yaml

# Custom tags
# '*':
# database_version:11.2
# database_version:18.7
# elasticsearch:version:5.6.9
# elasticsearch:version:6.8.4
# filebeat:version:6.8.4
# kibana:version:5.6.9
# logstash:version:5.6.9
# oci:shape:BM+
# osmajorrelease:6
# osmajorrelease:7

# Raw output
# -----
#file: /Users/mrex/GIT/SE/DOCKER/netsuite-configuration/salt/lab_infrastructure/manifest/lab/rundeck.yaml
# {'filebeat': [{'*': '5.6.9-1'}], 'rundeck': [{'*': '3.2.2.20200204-1'}], 'ns-jdk1.8': [{'*': '1.8.0_221-1.el6'}], 'ns-ojdbc': [{'*': '8.0.0-1.el6'}], 'ns-rash-rundeck-plugin': [{'*': '0.1.24-1.el6'}], 'ns-salt-call-rundeck-plugin': [{'*': '1.0.8-1.el6'}], 'ns-sleep-rundeck-plugin': [{'*': '0.1.4-1.el6'}]}
#-----

REPO_ROOTDIR = '/Users/mrex/GIT/SE/DOCKER/netsuite-configuration'
manifests = glob.glob('{0}/salt/*/manifest/*/*.yaml'.format(REPO_ROOTDIR), recursive=True)

for manifest in manifests:
    print('file: {0}'.format(manifest))
    with open(manifest, 'r') as stream:
        try:
            #print(yaml.safe_load(stream))
            package = yaml.safe_load(stream)
            if package:
                #for key, value in package.items():
                #    print('RPM: {0}'.format(key))
                #    print('Version: {0}'.format(value))
                #    print()
                #
                for rpm, values in package.items():
                    print('RPM: {0}'.format(rpm))
                    for block in values:
                        for ident, version in block.items():
                            print(' - ident: {0}'.format(ident))
                            print(' -- version_string: {0}'.format(version))
        except yaml.YAMLError as exc:
            print(exc)
    print('-----')
