# -*- coding: utf-8 -*-
'''
This module is intended to clean up old logrotate
configuration by deleting files created by
common_entitites.logrotate_configuration.  Having
deleted all of the files created by that state
all previous changes are rolled back, and thus a
fresh run of that state can be used to re-populate
a correct configuration.

Primarily this module has been writtent to serve
the changes made in TT-72799: "Logrotation breaks
after removing 11.2 from DB hosts, file used as
logrotation flag is inside version directory"
While it currently rolls back all the logrotate
files created by
common_entitites.logrotate_configuration,
obviously that salt state is dynamic, and is
subject to change in the future.

Currently this module takes no augments.  If
used via the 'salt' command it should be
targeted appropriately using via salt's own
mechanisms.
==========================
:maintainer: Marius Rex <mrex@netsuite.com>
:maturity: new
:platform: Linux
.. versionadded:: 2018.11.20
'''
import os
import salt.utils
import logging
log = logging.getLogger(__name__)

__virtualname__ = 'logrotate_config_cleanup'


def __virtual__():
    '''
    salt module to cleanup custom logrotate conf files
    '''
    return __virtualname__

def grab_ext (ext, dirname, names):
    '''
    Select files by file extention
    '''
    ext = ext.lower()

    for name in names:
        if name.lower().endswith(ext):
            path = os.path.join(dirname, name)
            if os.path.exists(path):
                os.remove(path)
                log.info(path)

def grab_prefix (pref, dirname, names):
    '''
    Select files by given file prefix
    '''
    pref = pref.lower()

    for name in names:
        if name.lower().startswith(pref):
            path = os.path.join(dirname, name)
            if os.path.exists(path):
                os.remove(path)
                log.info(path)

def etc_cron_d_logrotate():
    '''
    Deletes files created by "logrotate_configuration_etc_cron_d_logrotate_{{ logrotate_job }}"
    from common_entitites.logrotate_configuration
    '''
    topdir = '/etc/cron.d/'
    prefix = 'logrotate-'

    os.path.walk(topdir, grab_prefix, prefix)
    log.info('Cleaned up /etc/cron.d/logrotate-*')

    return 'Cleaned up /etc/cron.d/logrotate-*'

def etc_logrotate_ns_d():
    '''
    Deletes files created by "logrotate_configuration_etc_logrotate_d_{{ logrotate_job }}"
    from common_entitites.logrotate_configuration
    '''
    topdir = '/etc/logrotate.ns.d/'
    exten = ".conf"

    os.path.walk(topdir, grab_ext, exten)
    log.info('Cleaned up /etc/logrotate.ns.d/*.conf')

    return 'Cleaned up /etc/logrotate.ns.d/*.conf'

def logrotate_lrf():
    '''
    Deletes files created by "logrotate_{{ logrotate_job }}"
    from common_entitites.logrotate_configuration
    '''
    topdirs = ['/var/log',
               '/var/netsuite',
               '/opt/logs',
               '/opt/deploy',
               '/opt/oldtar',
               '/opt/install',
               '/opt/tdconsole',
               '/opt/nodemanager'
               '/opt/oramw'
              ]
    exten = ".lrf"

    for tdir in topdirs:
        os.path.walk(tdir, grab_ext, exten)

    log.info('Cleaned up *.lrf files from common locations')

    return 'Cleaned up *.lrf files from common locations'

def cleanup_all():
    '''
    Batch run of all included cleanup functions
    '''
    etc_cron_d_logrotate()
    etc_logrotate_ns_d()
    logrotate_lrf()

    return 'All cleanup routines run successful'

# vim: set ts=3 sw=3 tw=0 et :
