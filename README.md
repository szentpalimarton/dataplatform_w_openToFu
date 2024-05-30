opentofu needs to be downloaded first, on Mac:

brew install opentofu

then create a folder for the project:

mkdir data-platform-iac cd data-platform-iac

then copy the main.tf file into the new folder and run:

tofu init and tofu apply

State File: OpenToFu maintains the state of your infrastructure in a state file (e.g., terraform.tfstate). This file records the current state of the infrastructure managed by OpenToFu. Version Control: Store your OpenToFu configuration files and state files in a version control system (e.g., Git) to track changes and collaborate with team members.

Iceberg is configured inside the Trino container, not as a separate Docker service.
MinIO is used as the storage backend for Iceberg, providing the necessary S3-compatible storage.

