#!/usr/bin/python3
'''
This script was written to grab host information in
CSE-19231 - create tool to retrieve host information farm wide

This should be run from a host like
ops-mcl00[1-3].prod-phx.gs.nsgbu.internal in order to reach any and all
salt master hosts
'''

import getopt
import sys
from collections import defaultdict
sys.path.insert(0, './lib')
from helptext import help_output
from polecat import run_polecat


RESULTS_FILE= 'results.csv'
PLCAT_CMD =  "/opt/mcl-scripts/admin/polecat.mcl -force -noui --l "
SM_HOSTS =  False
SM_SUDO = 'sudo salt -C '
SM_ROLES = False
SM_FUNCTION = " cmd.run "
DQ = '"'
SQ = "'"
SM_CMDS = [ ]
REPORT_DICT = defaultdict(list)
RESULTS_FILE = 'results.csv'

# Fetch augment list
argumentList = sys.argv[1:]
CLI_OPTIONS = "hs:t:c:"
LONG_OPTIONS = ["help", "salt_master=", "salt_targets=", "salt_command"]
try:
    # Parse augments
    arguments, values = getopt.getopt(argumentList, CLI_OPTIONS, LONG_OPTIONS)

    # checking each argument
    for currentArgument, currentValue in arguments:

        if currentArgument in ("-h", "--help"):
            print("\nMissing one or more augments:")
            help_output()
            sys.exit(1)

        elif currentArgument in ("-s", "--salt_masters"):
            SM_HOSTS = currentValue

        elif currentArgument in ("-t", "--salt_targets"):
            SM_ROLES = currentValue

        elif currentArgument in ("-c", "--salt_command"):
            SM_CMDS.append(currentValue)

except getopt.error as err:
    print (str(err))

# Create a fresh empty results file.
RESULTS_FH = open(RESULTS_FILE, 'w', encoding="utf-8").close

# Try to run polecat command(s)
if SM_HOSTS and SM_ROLES and SM_CMDS:
    for SM_CMD in SM_CMDS:
        CMD = PLCAT_CMD \
              + SM_HOSTS + ' --cmd ' \
              + DQ \
              + SM_SUDO \
              + SQ + SM_ROLES + SQ \
              + SM_FUNCTION \
              + SQ + SM_CMD + SQ \
              + DQ
        rundata = run_polecat(CMD)
        #print(rundata)
        for host, cmd_output in rundata.items():
            REPORT_DICT[host].append(cmd_output)


else:
    print("\nAugments that are needed to be fed to polecat.mcl:")
    help_output()
    sys.exit(1)

with open(RESULTS_FILE, 'a', encoding="utf-8") as RESULTS_FH:
    print(f'\nAttempting to write out results to {RESULTS_FILE} file')
    # Interate through keys
    for key, values in REPORT_DICT.items():
        RESULTS_FH.write(key + ',')
        #print(f'{key},')
        for value in values:
            RESULTS_FH.write(value + ',')
            #print(f'{value} ,')
        RESULTS_FH.write('\n')
        #print('\n')

RESULTS_FH.close()
