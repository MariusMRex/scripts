''' Run polcat command and capture output '''
import re
import subprocess

def run_polecat(CMD):
    ''' Run polcat command and capture output '''
    # Regular expressions
    host_re = re.compile(r'(\w+\d{3}\.(f|snap|prod)-\w{3}.*internal).*:$')
    run_id_re = re.compile(r'.*mcl-control\s-resume\s(\d+)$')
    salt_output_re = re.compile(r'^\s{4}(.*)')
    pc_error_re = re.compile(r'.*(salt-master\d{3}.*internal).*Failed$')
    salt_master_re = re.compile(r'.*(salt-master\d{3}.*internal).*')
    salt_target_error_re = re.compile(r'^No\sminions\smatched.*target.*')
    cabinet = { }
    encoded_line = b''
    line = ''
    mcl_admin_cmd = "/opt/OpsMCL/engine/bin/mcl-control"
    mcl_run_id = ''

    print('\nExecuting:\n' + CMD)
    pc_run = subprocess.Popen(CMD,
                              shell=True,
                              stdout=subprocess.PIPE,
                              stderr=subprocess.PIPE)
    print('\n')
    for encoded_line in pc_run.stderr:
        # btye data needs to be decoded to perform a regex match
        line = encoded_line.decode("utf-8")

        salt_master_match = salt_master_re.match(line)
        if salt_master_match:
            salt_master = salt_master_match.group(1)

        host_match = host_re.match(line)
        if host_match:
            host =  host_match.group(1)

        salt_cmd_output_match = salt_output_re.match(line)
        if salt_cmd_output_match:
            salt_cmd_output = salt_cmd_output_match.group(1)
            cabinet[host] = salt_cmd_output

        # Catch error states
        pc_error_match = pc_error_re.match(line)
        if pc_error_match:
            pc_error = pc_error_match.group(1)
            print('\n#####')
            print(f'Error connecting to {pc_error}')
            print('Check hostname and make sure your user can log into this host')
            print('#####')

        salt_target_error_match = salt_target_error_re.match(line)
        if salt_target_error_match:
            print('\n#####')
            print('Warning: No minions matched the target')
            if salt_master:
                print(f'This likely was seen on {salt_master}')
                print('#####')

    # Grab polecat run id
    for encoded_line in pc_run.stdout:
        # btye data needs to be decoded to perform a regex match
        line = encoded_line.decode("utf-8")
        run_id_match = run_id_re.match(line)
        if run_id_match:
            mcl_run_id = run_id_match.group(1)

    # Clean up MCL run
    if mcl_run_id:
        CMD = mcl_admin_cmd + ' --abandon ' + mcl_run_id
        print('\nAttempting to abandon command on ID ' + mcl_run_id + ' to clean up mcl run.')
        mcladmin_run = subprocess.Popen(CMD,
                                        shell=True,
                                        stdout=subprocess.PIPE,
                                        stderr=subprocess.PIPE)
        # ToDo: Better Error Capture
        # Even when 100% successful the return code still does not equal '0'
        #if mcladmin_run.returncode != 0:
        #    error = mcladmin_run.stderr.read().decode()
        #    print('Error: ', error)
    else:
        print('Could not locate mcl run id of last polecat.')
        print('You may need to execute the mcl-admin "-abandon" command manually.')

    return cabinet
