locals {
  script_dest = "~/install_pbs.sh"
}

data "template_file" "execution" {
  template = "${file("${path.module}/../../scripts/install_pbs.sh")}"
}

resource "oci_core_instance" "execution" {
  count               = "${var.execution_count}"
  availability_domain = "${var.availability_domain}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "${var.display_name}${count.index+1}"
  shape               = "${var.shape}"

  create_vnic_details {
    subnet_id        = "${var.subnet_id}"
    display_name     = "${var.display_name}${count.index+1}"
    assign_public_ip = "${var.assign_public_ip}"
  }

  metadata {
    ssh_authorized_keys = "${file("${var.ssh_authorized_keys}")}"
  }

  source_details {
    source_id   = "${var.image_id}"
    source_type = "image"
  }

  timeouts {
    create = "10m"
  }

  provisioner "file" {
    connection = {
      host                = "${self.private_ip}"
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    content     = "${data.template_file.execution.rendered}"
    destination = "${local.script_dest}"
  }

  provisioner "remote-exec" {
    connection = {
      host                = "${self.private_ip}"
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    inline = [
      "chmod +x ${local.script_dest}",
      "${local.script_dest} execution",
    ]
  }
}
