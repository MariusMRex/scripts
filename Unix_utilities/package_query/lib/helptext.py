''' Help text output '''
def help_output():
    print(" -s/--salt_masters")
    print("   Example: -s salt-master201.f-iad-na4.core.ns.internal,salt-master201.f-phx-na5.core.ns.internal")
    print(" -t/--salt_targets")
    print("   Example: 'G@role:kafka or G@role:zookeeper or G@role:mono'")
    print("   When specifying multiple targets quotes are necessary, as seen above")
    print(" -c/--salt_commands")
    print("   Example: 'rpm -qa | grep NetLedger-nsh'")
    print("   When specifying a complex command, like above, quoting is required.")
    print("   This option can be specified multiple times to combine multiple pole runs.")
