#!/opt/homebrew/bin/python3
#
# Note Bene: This should work for medusa only from specific VLANs due to IAM policy
#
import oci

config = oci.config.from_file("~/.oci/config.medusa")


# Initialize service client with default config file
identity_client = oci.identity.IdentityClient(config)

# Initialize service client with default config file
object_storage_client = oci.object_storage.ObjectStorageClient(config)

put_object_response = object_storage_client.put_object(
    namespace_name="oraclenetsuite",
    bucket_name="NetSuite.Production..medusa-backups-PHX",
    object_name="test_upload",
    put_object_body=b"[Redacted]")

# Get the data from response
print(put_object_response.headers)
