resource "oci_core_instance" "bastion" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[var.bastion_ad_index - 1], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.bastion_display_name}"
  shape               = "${var.bastion_shape}"

  create_vnic_details {
    subnet_id        = "${oci_core_subnet.bastion.id}"
    assign_public_ip = true
  }

  metadata {
    ssh_authorized_keys = "${file("${var.bastion_authorized_keys}")}"
  }

  source_details {
    source_id   = "${var.image_ids[var.region]}"
    source_type = "image"
  }
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
  server_subnet_id       = "${oci_core_subnet.pbspro.id}"
  execution_count        = "${var.execution_count}"
  execution_display_name = "${var.execution_display_name}"
  execution_shape        = "${var.execution_shape}"
  execution_image_id     = "${var.image_ids[var.region]}"
  execution_subnet_id    = "${oci_core_subnet.pbspro.id}"
  bastion_host           = "${oci_core_instance.bastion.public_ip}"
  bastion_user           = "${var.bastion_user}"
  bastion_private_key    = "${var.bastion_private_key}"
}
