#!/usr/bin/python

import mysql.connector
import time
import datetime

host_array = ['p1-db01', 'p1-db02']
mysql_port = {{ pillar['mysql.port'] }}
connect_user = 'salt'
connect_passwd = '{{ pillar['mysql.salt_password'] }}'
internal_db_user = 'tribehr_root'
internal_db_user_passwd = '{{ pillar['mysql.tribehr_root_password'] }}'
ts = time.time()
timestamp = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')

config = {
  'user': connect_user,
  'password': connect_passwd,
  'host': '127.0.0.1',
  'database': 'tribehr_central',
  'raise_on_warnings': True,
}

cnx = mysql.connector.connect(**config)
cursor = cnx.cursor()

# Update tribehr_central.database_hosts 
truncate_table = ("TRUNCATE TABLE database_hosts")
cursor.execute(truncate_table)

for host in host_array:
  # Build host insert statement
  host_insert = ("INSERT INTO database_hosts "
    "(name, address, port, username, password, root_host, user_host, yield, created, modified) "
    "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)")

  host_insert_data = (host, host, mysql_port, internal_db_user, internal_db_user_passwd, '10.48.%', '10.48.%', '0', timestamp, timestamp)

  # Insert host data
  cursor.execute(host_insert, host_insert_data)

# Build account update statement
account_update = ("UPDATE accounts SET dbpass=%s WHERE id=%s")
account_update_data = (internal_db_user_passwd, '1')

# Update account data
cursor.execute(account_update, account_update_data)

# Update all database references in tribehr_central.accounts
update_to_db01 = ("UPDATE accounts SET dbserver=%s WHERE dbserver=%s")
update_to_db01_data = (host_array[0], 'prod-db01')
cursor.execute(update_to_db01, update_to_db01_data)

update_to_db02 = ("UPDATE accounts SET dbserver=%s WHERE dbserver=%s")
update_to_db02_data = (host_array[1], 'prod-db02')
cursor.execute(update_to_db02, update_to_db02_data)

# Commit all changes
cnx.commit()

cursor.close()
cnx.close()
