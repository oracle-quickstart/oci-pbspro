provider "oci" {
  tenancy_ocid     = "${var.tenancy_ocid}"
  user_ocid        = "${var.user_ocid}"
  fingerprint      = "${var.fingerprint}"
  private_key_path = "${var.private_key_path}"
  region           = "${var.region}"
}

data "oci_identity_availability_domains" "ad" {
  compartment_id = "${var.tenancy_ocid}"
}

module "pbspro" {
  source                 = "../../"
  compartment_ocid       = "${var.compartment_ocid}"
  availability_domain    = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[var.ad_index - 1], "name")}"
  ssh_authorized_keys    = "${var.ssh_authorized_keys}"
  ssh_private_key        = "${var.ssh_private_key}"
  server_display_name    = "${var.server_display_name}"
  server_shape           = "${var.server_shape}"
  server_image_id        = "${var.image_ids[var.region]}"
  server_subnet_id       = "${var.subnet_id}"
  execution_count        = "${var.execution_count}"
  execution_display_name = "${var.execution_display_name}"
  execution_shape        = "${var.execution_shape}"
  execution_image_id     = "${var.image_ids[var.region]}"
  execution_subnet_id    = "${var.subnet_id}"
  bastion_host           = "${var.bastion_host}"
  bastion_user           = "${var.bastion_user}"
  bastion_private_key    = "${var.bastion_private_key}"
}
