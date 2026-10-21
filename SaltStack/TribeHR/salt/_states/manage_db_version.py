# -*- coding: utf-8 -*-
'''
This state is intended as a manual way to manage
the value for the oracle database version.

As part of TT-77330 the grain dns_tags:db_version
was implimented to provide a way for salt to
track the active oracle version on a box.

In SYSCONF-60 it was requested a one-off to
set the grain manually.
==========================
:maintainer: Marius Rex <mrex@netsuite.com>
:maturity: new
:depends:  re, sys
:platform: Linux
.. versionadded:: 2019.05.13
'''
import logging
import re
import sys
import subprocess
import salt.utils
import salt.exceptions
LOG = logging.getLogger(__name__)

__virtualname__ = 'manage_db_version'

def __virtual__():
    '''
    salt state to set oracle_db_version grain
    '''
    return __virtualname__


def update_profile_path_sh():
    '''
    Immediately update /etc/profile.d/path.sh.

    Originally this was scheduled to run once an hour via
    salt_pillar/pillars/scheduled_tasks_unified.sls. 
    Though this functionality is expected to be de-activated 
    in the near future.

    CLI Example:
       salt manage_db_version.update_profile_path_sh
    '''
    #__salt__['state.sls']('base.oneoffs.databaseserver_etc_profiled_path_sh')
    profile_path_ret = __states__['base.oneoffs.databaseserver_etc_profiled_path_sh']()
    return profile_path_ret.values()[0]

def package_install():
    '''
    Ensure that proper database packages are installed
    via salt-call

    CLI Example:
       salt manage_db_version.package_install
    '''
    ret = {
        'name': 'Update db_version_override package install',
        'changes': {},
        'result': None,
        'comment': ''
        }

    #__salt__['state.sls']('database.databaseserver_packages_by_grain')
    #ret = __states__['database.databaseserver_packages_by_grain']()
    #sub_ret = __states__['database.databaseserver_packages_by_grain']()
    p = subprocess.Popen("/usr/bin/salt-call", "state.apply", "database.databaseserver_packages_by_grain")
    response, header = p.communicate()
    p.wait
    #if sub_ret['result'] == False or sub_ret['result'] == None:
    #    return sub_ret


    #if sub_ret['changes']:
    #    ret['changes'].update({'1- Package update complete.': sub_ret['changes']})

    return response, header

def via_grain(ora_version):
    '''
    Sets oracle_db_version grain from input
    given on the command line

    CLI Example:
       salt manage_db_version.via_grain 18.5
    '''
    ret = {
        'name': 'Update db_version_override grain',
        'changes': {},
        'result': None,
        'comment': ''
        }

    ora_version = sys.argv[2]
    db_version_regex = re.compile(r'\d\d\.\d')
    db_version_match = db_version_regex.match(ora_version)
    if db_version_match:
        grain_output = __salt__['grains.get']('db_version_override')
        if grain_output == ora_version:
            ret['result'] = True
            ret['comment'] = 'Grain db_version_override already in the correct state.'
            return ret

        # Is this running in test mode?
        if __opts__['test']:
            ret['comment'] = 'Grain db_version_override will be changed.'
            ret['changes'] = {
                'old': grain_output,
                'new': ora_version,
            }

            # Return ``None`` when running with ``test=true``.
            ret['result'] = None

            return ret

        # Make the change to the grain
        updated_grain = __salt__['grains.set']('db_version_override', '{0}'.format(ora_version))

        ret['comment'] = 'Grain db_version_override will be changed.'

        ret['changes'] = {
            'old': grain_output,
            'new': updated_grain,
        }

        ret['result'] = True

        LOG.info('Set db_version_override grain locally.')
        update_profile_path_sh()
        package_install()

        return ret

    else:
        LOG.info('Provided input %s does not seem to be a valid Oracle DB version', ora_version)
        raise salt.exceptions.SaltInvocationError(
            'Provided input {0} does not seem to be a valid Oracle DB version'.format(ora_version))

# vim: set filetype=python sts=4 ts=4 sw=4 tw=0 colorcolumn=100 et :
