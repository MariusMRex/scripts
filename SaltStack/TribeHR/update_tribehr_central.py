#!/usr/bin/python

import mysql.connector
import time
import datetime

{%- if pillar['mysql.database_masterhosts'] %}
host_array = {{ pillar['mysql.database_masterhosts'] }}
{%- endif %}
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

{% if pillar['mysql.database_masterhosts'] %}
for host in host_array:
  # Build host insert statement
  host_insert = ("INSERT INTO database_hosts "
    "(name, address, port, username, password, root_host, user_host, yield, created, modified) "
    "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)")

  host_insert_data = (host, host, mysql_port, internal_db_user, internal_db_user_passwd, '%', '%', '0', timestamp, timestamp)

  # Insert host data
  cursor.execute(host_insert, host_insert_data)

# Build account update statement
account_update = ("UPDATE accounts SET dbserver=%s, dbuser=%s, dbpass=%s, dbport=%s WHERE id=%s")
account_update_data = (host_array[0], internal_db_user, internal_db_user_passwd, mysql_port, '1')

# Update account data
cursor.execute(account_update, account_update_data)

{% endif %}
# Commit all changes
cnx.commit()

cursor.close()
cnx.close()
