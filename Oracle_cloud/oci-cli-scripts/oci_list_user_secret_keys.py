#!/opt/homebrew/bin/python3
# This is an automatically generated code sample.
# To make this code sample work in your Oracle Cloud tenancy,
# please replace the values for any parameters whose current values do not fit
# your use case (such as resource IDs, strings containing ‘EXAMPLE’ or ‘unique_id’, and
# boolean, number, and enum parameters with values not fitting your use case).
# Source: https://docs.oracle.com/en-us/iaas/api/#/en/identity/20160918/CustomerSecretKeySummary/ListCustomerSecretKeys
#
# Using this for user medusa.  So I swapped the symlink in ~/.oci to point to the medusa config
# I ran this on my oracle linux VM as it was easier to install python modules.

import oci

# Create a default config using DEFAULT profile in default location
# Refer to
# https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/sdkconfig.htm#SDK_and_CLI_Configuration_File
# for more info
config = oci.config.from_file()


# Initialize service client with default config file
identity_client = oci.identity.IdentityClient(config)


# Send the request to service, some parameters are not required, see API
# doc for more info
list_customer_secret_keys_response = identity_client.list_customer_secret_keys(
    user_id="ocid1.user.oc1..[Redacted]")

    # Get the data from response
print(list_customer_secret_keys_response.data)
