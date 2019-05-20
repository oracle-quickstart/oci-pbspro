# oci-quickstart-pbspro

These are Terraform modules that deploy [PBS Pro](https://www.pbspro.org/) on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure).

## Prerequisites

See the [Oracle Cloud Infrastructure Terraform Provider docs](https://www.terraform.io/docs/providers/oci/index.html) for information about setting up and using the Oracle Cloud Infrastructure Terraform Provider.

## How to Use the Module
Module structure:
* [root](./): It configures both the server and the execution hosts in the cluster.
* [modules](./modules/): It creates the compute resources for the server and the execution hosts repectively.
* [examples](./examples/): 
  - [quick_start](./examples/quick_start): It will create compute resources along with all the required networking such as VCN, subnets, etc.
  - [existing_infra](./examples/existing_infra) It's applicable to existing networking/bastion infra and to provision the compute instances only.

The following code shows how to deploy the PBS Pro Cluster using this module:

```hcl
module "pbspro" {
  source                 = "../../"
  compartment_ocid       = "${var.compartment_ocid}"
  availability_domain    = "${var.availability_domain}"
  ssh_authorized_keys    = "${var.ssh_authorized_keys}"
  ssh_private_key        = "${var.ssh_private_key}"
  server_display_name    = "${var.server_display_name}"
  server_shape           = "${var.server_shape}"
  server_image_id        = "${var.image_ids[var.region]}"
  server_subnet_id       = "${var.subnet_id}"
  execution_count        = "${var.execution_count}"
  execution_display_name = "${var.execution_display_name}"
  execution_shape        = "${var.execution_shape}"
  execution_image_id     = "${var.image_id}"
  execution_subnet_id    = "${var.subnet_id}"
  bastion_host           = "${var.bastion_public_ip}"
  bastion_user           = "${var.bastion_user}"
  bastion_private_key    = "${var.bastion_private_key}"
}
```

**Following are arguments available to the module:**

Argument | Description
--- | ---
compartment_ocid | Unique identifier (OCID) of the compartment in which to create the PBS Pro cluster in.
availability_domain | The Availability Domain for the PBS cluster.
ssh_authorized_keys | Public SSH keys to be included in the ~/.ssh/authorized_keys file for the default user on the instance.
ssh_private_key | The private key path to access instances.
server_display_name | The display name of the PBS Pro server.
server_shape | The shape for the PBS Pro server.
server_image_id | The OCID of the image for the PBS Pro server.
server_assign_public_ip | Whether the VNIC should be assigned a public IP address.
server_subnet_id | The subnet id to host the PBS Pro server.
execution_count | The number of the PBS Pro execution hosts.
execution_display_name | The display name of the PBS Pro execution hosts.
execution_shape | The shape for the PBS Pro execution hosts.
execution_image_id | The OCID of the image for the PBS Pro execution hosts.
execution_assign_public_ip | Whether the VNIC should be assigned a public IP address.
execution_subnet_id | The subnet id to host the PBS Pro execution hosts.
