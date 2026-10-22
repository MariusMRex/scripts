#!/usr/bin/python
# This script was partially written with aider, the AI coding assistent provided though Oracle
# Originally I was using a jinja templete in salt, to create a python script, which referenced a jinja template
import os
import socket
import subprocess
import re
import argparse
import shutil
from jinja2 import Environment, FileSystemLoader

table_list_file = "/opt/oracle/migrator/table_names.txt"
flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC  # Write-only, create if not exists, truncate file
mode = 0o600  # Set file mode to -rw-------
table_list = []
local_backup_dir = "/home/release/nosql-backups/"
local_backup_config_path = os.path.join('/opt/oracle/migrator', 'local-backup-configs')
local_restore_config_path = os.path.join('/opt/oracle/migrator', 'local-restore-configs')
target = 'unknown'


def grab_tables():
    """
    Grab list of relevant NoSQL tables to dynamicaly build list for backups
    """
    table_re = re.compile(r'((.*):(.*))')
    hostname = socket.gethostname()
    helper = hostname + ':5000'

    command = [
        "/opt/jdk21/bin/java", "-Xmx64m", "-Xms64m",
        "-Doracle.kv.security=/opt/oracle/nosql/kvroot/security/bds.login", "-jar",
        "/opt/oracle/nosql/lib/sql.jar", '-helper-hosts', helper,
        "-store", "Netsuite", "SHOW TABLES"
    ]

    try:
        subprocess_output = subprocess.run(command, stdout=subprocess.PIPE,
                                           stderr=subprocess.STDOUT,
                                           universal_newlines=True, check=False)
    except subprocess.CalledProcessError as e:
        subprocess_output = e.output

    all_tables = subprocess_output.stdout.split()
    for table in all_tables:
        includes_namespace = table_re.match(table)
        if includes_namespace:
            table_list.append(includes_namespace.group(1))
    return table_list


def write_table_list():
    """
    Write out the master table list file to feed to the backup system
    """
    b_tables = os.open(table_list_file, flags, mode)
    with os.fdopen(b_tables, 'w') as f:
        for table in table_list:
            f.write(table + "\n")


def write_backup_configs():
    """
    Invoke jinja template to write out NoSQL migrator configuration files to backup tables
    """
    global target
    # loading the environment
    env = Environment(loader = FileSystemLoader('/opt/oracle/migrator/scripts/migrator_templates'))
    # loading the template
    if target == 'local':
        template = env.get_template('local-backup-config.j2')
    else:
        template = env.get_template('backup-config.j2')

    # Create a backup config for each table
    for table in table_list:
        # rendering the template and storing the resultant text in variable output
        output = template.render(backup_table = table, backup_dir = local_backup_dir)
        if target == 'local':
            #output_file = '/opt/oracle/migrator/local-backup-configs/' + table + '-local-backup.conf'
            output_file = local_backup_config_path + '/' + table + '-local-backup.conf'
        else:
            output_file = '/opt/oracle/migrator/backup-configs/' + table + '-backup.conf'
        with open(output_file, 'w') as backup_config:
            print(output, file = backup_config)


def write_restore_configs():
    """
    Invoke jinja template to write out NoSQL migrator configuration files to restore tables
    """
    global target
    # loading the environment
    env = Environment(loader = FileSystemLoader('/opt/oracle/migrator/scripts/migrator_templates'))
    # loading the template
    if target == 'local':
        template = env.get_template('local-restore-config.j2')
    else:
        template = env.get_template('restore-config.j2')

    # Create a restore config for each table
    for table in table_list:
        # rendering the template and storing the resultant text in variable output
        output = template.render(restore_table = table, backup_dir = local_backup_dir)
        if target == 'local':
            #output_file = '/opt/oracle/migrator/local-restore-configs/' + table + '-local-restore.conf'
            output_file = local_restore_config_path + '/' + table + '-local-restore.conf'
        else:
            output_file = '/opt/oracle/migrator/restore-configs/' + table + '-restore.conf'
        with open(output_file, 'w') as restore_config:
            print(output, file = restore_config)


def clean_local_backup_configs():
    if os.path.isdir(local_backup_dir):
        shutil.rmtree(local_backup_dir)
    if os.path.isdir(local_backup_config_path):
        shutil.rmtree(local_backup_config_path)
    if os.path.isdir(local_restore_config_path):
        shutil.rmtree(local_restore_config_path)
    print('Cleaned up all paths')


def main():
    global target
    parser = argparse.ArgumentParser(
        description="Catalog all NoSQL tables and generate appropriate backup/restore configs to use with Oracle NoSQL Migrator"
    )
    parser.add_argument(
        "--local", action="store_true",
        help="Only generate backup and restore configs for local backups"
    )
    parser.add_argument(
        "--clean-local", action="store_true",
        help="Clean up local backup and restore files as they are no longer needed"
    )

    args = parser.parse_args()
    if args.local:
        target = 'local'
        if not os.path.isdir(local_backup_dir):
            os.mkdir(local_backup_dir)
        if not os.path.isdir(local_backup_dir):
            os.mkdir(local_backup_dir)
        if not os.path.isdir(local_backup_config_path):
            os.mkdir(local_backup_config_path)
        if not os.path.isdir(local_restore_config_path):
            os.mkdir(local_restore_config_path)
        grab_tables()
        write_backup_configs()
        write_restore_configs()
    elif args.clean_local:
        clean_local_backup_configs()
    else:
        target = 'cloud'
        grab_tables()
        write_table_list()
        write_backup_configs()
        write_restore_configs()

if __name__ == "__main__":
    main()
