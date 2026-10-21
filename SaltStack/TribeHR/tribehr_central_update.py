# -*- coding: utf-8 -*-
'''
tribehr_central_update should be run manually after doing a full dump and
restore from the live TribeHR data.  It is intended to update database names and
ips
'''
import salt.utils
import time
import datetime

try:
    import MySQLdb
    HAS_LIBS = True
except ImportError:
    HAS_LIBS = False

import logging
log = logging.getLogger(__name__)

__virtualname__ = 'tribehr_central_update'

def __virtual__():
  '''
  Check dependencies
  '''
  if not salt.utils.path.which('mysql'):
    return False

  if HAS_LIBS:
    return __virtualname__

  return False


def _get_conn():
  '''
  Get a database connection object
  '''
  connect_user = __salt__['config.get']('mysql.salt_user', 'salt')
  connect_passwd = __salt__['config.get']('mysql.salt_password', '')
  host = __salt__['config.get']('mysql.host', 'localhost')
  socket = __salt__['config.get']('mysql.unix_socket', '/var/lib/mysql/mysql.sock')
  db_= 'tribehr_central'
  dbc = MySQLdb.connect(
    host=host,
    user=connect_user,
    passwd=connect_passwd,
    db=db_,
    unix_socket=socket,
  )
  log.debug('Connected to the database')
  return dbc

def version():
  '''
  Returns MySQL Version

  CLI Example:
    salt '*' tribehr_central_update.version
  '''
  dbc = _get_conn()
  cur = dbc.cursor()
  cur.execute('SELECT VERSION()')
  return cur.fetchone()

def fix_database_hosts():
  '''
  Removes all entries from tribehr_central.database_hosts and populates
  the table with current relevant entries.
  
  CLI Example:
    salt '*' tribehr_central_update.fix_database_hosts
  '''
  master_list = __salt__['config.get']('mysql.database_masterhosts', ['p1-db01', 'p1-db02'])
  internal_db_user = __salt__['config.get']('mysql.tribehr_user', 'tribehr_root')
  internal_db_user_passwd = __salt__['config.get']('mysql.tribehr_root_password', '')
  mysql_port = __salt__['config.get']('mysql.port', '3306')
  net = __salt__['config.get']('env.network_prefix', '10.48')
  net_prefix = str(net) + '.%'
  ts_ = time.time()
  timestamp = datetime.datetime.fromtimestamp(ts_).strftime('%Y-%m-%d %H:%M:%S')
  dbc = _get_conn()
  cur = dbc.cursor()
  cur.execute('TRUNCATE TABLE database_hosts')

  for master in master_list:
    host_insert = ("INSERT INTO database_hosts "
      "(name, address, port, username, password, root_host, user_host, yield, created, modified) "
      "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)")

    host_insert_data = (master, master, mysql_port, internal_db_user, internal_db_user_passwd, net_prefix, net_prefix, '0', timestamp, timestamp)

    # Insert host data
    cur.execute(host_insert, host_insert_data)

    return 'tribehr_central.database_hosts updated'

def fix_accounts():
  '''
  Update password for master account in tribehr_central.accounts database.
  The correct password from account id '1' is pulled from the salt configs
  
  CLI Example:
    salt '*' tribehr_central_update.fix_accounts
  '''
  dbc = _get_conn()
  cur = dbc.cursor()
  internal_db_user_passwd = __salt__['config.get']('mysql.tribehr_root_password', '')
  account_update = ("UPDATE accounts SET dbpass=%s WHERE id=%s")
  account_update_data = (internal_db_user_passwd, '1')

  # Update account data
  cur.execute(account_update, account_update_data)

  return 'Updated password for tribehr_root'

def update_db_refs(oldname):
  '''
  Updates client sites with new database names.
  Expects an augment of the old database name

  CLI Example:
    salt '*'  tribehr_central_update prod-db
  '''
  dbc = _get_conn()
  cur = dbc.cursor()
  master_list = __salt__['config.get']('mysql.database_masterhosts', ['p1-db01', 'p1-db02'])
  count = 1
  
  for master in master_list:
    new_name = str(oldname) + '0' + str(count)
    update_db_owner = ("UPDATE accounts SET dbserver=%s WHERE dbserver=%s")
    update_db_owner_data = (master, new_name)

    cur.execute(update_db_owner, update_db_owner_data)
    count += 1
    
  return 'Database owners updated.'
