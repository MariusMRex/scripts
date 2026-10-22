#!/opt/homebrew/bin/python3
# This is an automatically generated code sample.
# To make this code sample work in your Oracle Cloud tenancy,
# please replace the values for any parameters whose current values do not fit
# your use case (such as resource IDs, strings containing ‘EXAMPLE’ or ‘unique_id’, and
# boolean, number, and enum parameters with values not fitting your use case).
#
# The version on my oracle linux box is proabably better with python modules.

import oci

name="medusa"
uid="ocid1.user.oc1..[Redacted]"
retry="NoneRetryStrategy"

# Create a default config using DEFAULT profile in default location
# Refer to
# https://docs.cloud.oracle.com/en-us/iaas/Content/API/Concepts/sdkconfig.htm#SDK_and_CLI_Configuration_File
# for more info
config = oci.config.from_file()


# Initialize service client with default config file
identity_client = oci.identity.IdentityClient(config)


# Send the request to service, some parameters are not required, see API
# doc for more info
create_customer_secret_key_response = identity_client.create_customer_secret_key(
    create_customer_secret_key_details=oci.identity.models.CreateCustomerSecretKeyDetails(
        display_name=name),
    user_id=uid,
    opc_retry_token=retry)

# Get the data from response
print(create_customer_secret_key_response.data)
