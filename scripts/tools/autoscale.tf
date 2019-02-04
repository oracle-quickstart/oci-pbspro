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

locals {
  reconfig_script = "/opt/tools/agent/config_cluster.sh"
}

data "template_file" "reconfig_cluster" {
  #template = "/opt/tools/agent/config_cluster.sh"
  template = "${file("${local.reconfig_script}")}"

  vars = {
    execution_host_names = "${join(" ", "${oci_core_instance.extend_host.*.display_name}")}"
    execution_ips        = "${join(" ", "${oci_core_instance.extend_host.*.private_ip}")}"
  }
}

resource "null_resource" "reconfig" {
  provisioner "local-exec" {
    command = "${data.template_file.reconfig_cluster.rendered}"
  }
}

output "Extended_Host_Names" {
 value = ["${oci_core_instance.extend_host.*.display_name}"]
}

output "Extended_Host_Private_IPs" {
 value = ["${oci_core_instance.extend_host.*.private_ip}"]
}