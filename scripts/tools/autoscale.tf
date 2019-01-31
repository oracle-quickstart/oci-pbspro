variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}

variable "compartment_ocid" {}
variable "ssh_authorized_keys" {
  default = "/home/opc/tmp.key.pub"
}

variable "execution_shape" {
  default     = "VM.Standard2.2"
}
variable "execution_subnet_name" {
  default = "pbspro_ad1"
}
variable "execution_vcn_name" {
  default = "pbspro"
}

variable "scale_num" {
  default = "2"
}
variable "execution_display_name" {
  default = "pbsproexecimage"
}

provider "oci" {
  tenancy_ocid         = "${var.tenancy_ocid}"
  user_ocid            = "${var.user_ocid}"
  fingerprint          = "${var.fingerprint}"
  private_key_path     = "${var.private_key_path}"
  region               = "${var.region}"
  disable_auto_retries = "true"
}

data "oci_identity_availability_domains" "ad" {
    compartment_id = "${var.tenancy_ocid}"
}

data "template_file" "ads" {
    count = "${length(data.oci_identity_availability_domains.ad.availability_domains)}"
    template = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[count.index], "name")}"
}

data "oci_core_images" "pbspro_execution_image" {
    compartment_id = "${var.compartment_ocid}"
    filter {
        name = "display_name"
        values = ["pbsproexecimage"]
    }
}

data "oci_core_vcns" "cluster_vnc" {
    compartment_id = "${var.compartment_ocid}"
    filter {
            name = "display_name"
            values = ["${var.execution_vcn_name}"]
    }
}

data "oci_core_subnets" "cluster_subnet" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${data.oci_core_vcns.cluster_vnc.virtual_networks.0.id}"
    filter {
            name = "display_name"
            values = ["${var.execution_subnet_name}"]
    }
}

resource "oci_core_instance" "extend_host" {
    count = "${var.scale_num}"

    availability_domain = "${data.oci_core_subnets.cluster_subnet.subnets.0.availability_domain}"
    compartment_id = "${var.compartment_ocid}"
    display_name = "${var.execution_display_name}0${count.index+1}"
    shape = "${var.execution_shape}"

    create_vnic_details {
        subnet_id = "${data.oci_core_subnets.cluster_subnet.subnets.0.id}"
        # display_name = "${var.execution_display_name}0${count.index+1}"
        # hostname_label = "${var.execution_display_name}0${count.index+1}"
        assign_public_ip = "false"
    }

    metadata {
        ssh_authorized_keys = "${file("${var.ssh_authorized_keys}")}"
    }

    source_details {
        source_id = "${data.oci_core_images.pbspro_execution_image.images.0.id}"
        source_type = "image"
    }

    timeouts {
        create = "10m"
    }
}

data "template_file" "reconfig_cluster" {
  template = "/home/opc/tools/image/config_cluster.sh"

  vars = {
    execution_host_names = "${join(" ", "${oci_core_instance.extend_host.*.display_name}")}"
    execution_ips        = "${join(" ", "${oci_core_instance.extend_host.*.private_ip}")}"
  }
}

resource "null_resource" "reconfig" {

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
      "chmod auo+x /home/opc/tools/config_cluster.sh",
      "./home/opc/tools/config_cluster.sh  > /home/opc/tools/config_cluster.log'",
    ]
  }
}

output "Extended_Host_Names" {
 value = ["${oci_core_instance.extend_host.*.display_name}"]
}

output "Extended_Host_Private_IPs" {
 value = ["${oci_core_instance.extend_host.*.private_ip}"]
}