# -*- coding: utf-8 -*-
'''
This module is intended as a manual way to manage
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
.. versionadded:: 2019.05.07
'''
import logging
import re
import sys
import salt.utils
LOG = logging.getLogger(__name__)

__virtualname__ = 'manage_db_version'


def __virtual__():
    '''
    salt module to set oracle_db_version grain
    '''
    return __virtualname__

def update_profile_path_sh():
    '''
    Immediately update /etc/profile.d/path.sh.

    CLI Example:
       salt manage_db_version.update_profile_path_sh
    '''
    #__salt__['state.apply']('base.oneoffs.databaseserver_etc_profiled_path_sh')
    __salt__['state.sls']('base.oneoffs.databaseserver_etc_profiled_path_sh')

def package_install():
    '''
    Ensure that proper database packages are installed
    via salt-call

    CLI Example:
       salt manage_db_version.package_install
    '''
    #__salt__['state.apply']('database.databaseserver_packages_by_grain')
    #__states__['state.apply']('database.databaseserver_packages_by_grain')
    __salt__['state.sls']('database.databaseserver_packages_by_grain')
    #__states__['state.single']('database.databaseserver_packages_by_grain')

def via_grain(ora_version):
    '''
    Sets oracle_db_version grain from input
    given on the command line

    CLI Example:
       salt manage_db_version.via_grain 18.5
    '''
    ora_version = sys.argv[2]
    db_version_regex = re.compile(r'\d\d\.\d')
    db_version_match = db_version_regex.match(ora_version)
    if db_version_match:
        __salt__['grains.set']('db_version_override', '{0}'.format(ora_version))

        update_profile_path_sh()
        package_install()

        LOG.info('Set db_version_override grain locally.')
    else:
        LOG.info('Provided input %s does not seem to be a valid Oracle DB version', ora_version)


# vim: set filetype=python sts=4 ts=4 sw=4 tw=0 colorcolumn=100 et :
