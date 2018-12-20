module "pbspro_execution" {
  source              = "./modules/pbspro-execution"
  execution_count     = "${var.execution_count}"
  availability_domain = "${var.availability_domain}"
  compartment_ocid    = "${var.compartment_ocid}"
  display_name        = "${var.execution_display_name}"
  image_id            = "${var.execution_image_id}"
  shape               = "${var.execution_shape}"
  subnet_id           = "${var.execution_subnet_id}"
  assign_public_ip    = "${var.execution_assign_public_ip}"
  ssh_authorized_keys = "${var.ssh_authorized_keys}"
  ssh_private_key     = "${var.ssh_private_key}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
}

module "pbspro_server" {
  source              = "./modules/pbspro-server"
  availability_domain = "${var.availability_domain}"
  compartment_ocid    = "${var.compartment_ocid}"
  display_name        = "${var.server_display_name}"
  image_id            = "${var.server_image_id}"
  shape               = "${var.server_shape}"
  subnet_id           = "${var.server_subnet_id}"
  assign_public_ip    = "${var.server_assign_public_ip}"
  ssh_authorized_keys = "${var.ssh_authorized_keys}"
  ssh_private_key     = "${var.ssh_private_key}"
  bastion_host        = "${var.bastion_host}"
  bastion_user        = "${var.bastion_user}"
  bastion_private_key = "${var.bastion_private_key}"
}

data "oci_core_subnet" "server" {
  subnet_id = "${var.server_subnet_id}"
}

locals {
  execution_script_dest = "~/config_execution.sh"
  cluster_script_dest   = "~/config_cluster.sh"
  private_key_dest      = "/home/opc/.ssh/id_rsa"
  server_domain_name    = "${var.server_display_name}.${data.oci_core_subnet.server.subnet_domain_name}"
}

data "template_file" "config_execution" {
  template = "${file("${path.module}/scripts/config_execution.sh")}"

  vars = {
    server_ip          = "${module.pbspro_server.private_ip}"
    server_host_name   = "${var.server_display_name}"
    server_domain_name = "${local.server_domain_name}"
  }
}

resource "null_resource" "execution" {
  count = "${var.execution_count}"

  provisioner "file" {
    connection = {
      host                = "${module.pbspro_execution.private_ips[count.index]}"
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    content     = "${data.template_file.config_execution.rendered}"
    destination = "${local.execution_script_dest}"
  }

  provisioner "file" {
    connection = {
      host                = "${module.pbspro_execution.private_ips[count.index]}"
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    source      = "${var.ssh_private_key}"
    destination = "${local.private_key_dest}"
  }

  provisioner "remote-exec" {
    connection = {
      host                = "${module.pbspro_execution.private_ips[count.index]}"
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    inline = [
      "chmod 600 ~/.ssh/id_rsa",
      "chmod +x ${local.execution_script_dest}",
      "${local.execution_script_dest}",
    ]
  }
}

data "template_file" "config_cluster" {
  template = "${file("${path.module}/scripts/config_cluster.sh")}"

  vars = {
    execution_host_names = "${join(" ", module.pbspro_execution.host_names)}"
    execution_ips        = "${join(" ", module.pbspro_execution.private_ips)}"
  }
}

resource "null_resource" "cluster" {
  triggers {
    execution_host_names = "${join(" ", module.pbspro_execution.host_names)}"
  }

  provisioner "file" {
    connection = {
      host                = "${module.pbspro_server.private_ip}"
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    content     = "${data.template_file.config_cluster.rendered}"
    destination = "${local.cluster_script_dest}"
  }

  provisioner "remote-exec" {
    connection = {
      host                = "${module.pbspro_server.private_ip}"
      agent               = false
      timeout             = "5m"
      user                = "opc"
      private_key         = "${file("${var.ssh_private_key}")}"
      bastion_host        = "${var.bastion_host}"
      bastion_user        = "${var.bastion_user}"
      bastion_private_key = "${file("${var.bastion_private_key}")}"
    }

    inline = [
      "chmod +x ${local.cluster_script_dest}",
      "${local.cluster_script_dest}",
    ]
  }
}
