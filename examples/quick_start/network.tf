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

resource "oci_core_virtual_network" "pbspro" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "pbspro"
  cidr_block     = "${var.vcn_cidr}"
  dns_label      = "pbspro"
}

resource "oci_core_internet_gateway" "pbspro" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.pbspro.id}"
  display_name   = "pbsproig"
}

resource "oci_core_nat_gateway" "pbspro" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.pbspro.id}"
  display_name   = "pbspronat"
}

resource "oci_core_route_table" "public" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.pbspro.id}"
  display_name   = "public"

  route_rules {
    destination       = "${local.anywhere}"
    network_entity_id = "${oci_core_internet_gateway.pbspro.id}"
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.pbspro.id}"
  display_name   = "private"

  route_rules {
    destination       = "${local.anywhere}"
    network_entity_id = "${oci_core_nat_gateway.pbspro.id}"
  }
}

locals {
  tcp_protocol          = "6"
  ssh_port              = "22"
  anywhere              = "0.0.0.0/0"
  dmz_tier_prefix       = "${cidrsubnet(var.vcn_cidr, 4, 0)}"
  app_tier_prefix       = "${cidrsubnet(var.vcn_cidr, 4, 1)}"
  bastion_subnet_prefix = "${cidrsubnet(local.dmz_tier_prefix, 4, 0)}"
}

resource "oci_core_security_list" "bastion" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "bastion"
  vcn_id         = "${oci_core_virtual_network.pbspro.id}"

  ingress_security_rules = [{
    source   = "${local.anywhere}"
    protocol = "${local.tcp_protocol}"

    tcp_options {
      "max" = "${local.ssh_port}"
      "min" = "${local.ssh_port}"
    }
  }]

  egress_security_rules = [{
    destination = "${local.app_tier_prefix}"
    protocol    = "${local.tcp_protocol}"

    tcp_options {
      "min" = "${local.ssh_port}"
      "max" = "${local.ssh_port}"
    }
  }]
}

resource "oci_core_security_list" "pbspro" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "pbspro"
  vcn_id         = "${oci_core_virtual_network.pbspro.id}"

  ingress_security_rules = [{
    source   = "${var.vcn_cidr}"
    protocol = "${local.tcp_protocol}"

    tcp_options {
      "max" = "${local.ssh_port}"
      "min" = "${local.ssh_port}"
    }
  },
    {
      source   = "${local.app_tier_prefix}"
      protocol = "${local.tcp_protocol}"

      tcp_options {
        "max" = "17001"
        "min" = "17001"
      }
    },
    {
      source   = "${local.app_tier_prefix}"
      protocol = "${local.tcp_protocol}"

      tcp_options {
        "max" = "15004"
        "min" = "15001"
      }
    },
  ]

  egress_security_rules = [{
    destination = "${local.anywhere}"
    protocol    = "${local.tcp_protocol}"
  }]
}

resource "oci_core_subnet" "bastion" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[var.bastion_ad_index - 1], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "bastion_ad${var.bastion_ad_index}"
  dns_label           = "bastion"
  cidr_block          = "${cidrsubnet(local.bastion_subnet_prefix, 4, 0)}"
  security_list_ids   = ["${oci_core_security_list.bastion.id}"]
  vcn_id              = "${oci_core_virtual_network.pbspro.id}"
  route_table_id      = "${oci_core_route_table.public.id}"
}

resource "oci_core_subnet" "pbspro" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[var.ad_index - 1], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "pbspro_ad${var.ad_index}"
  dns_label           = "pbspro"
  cidr_block          = "${cidrsubnet(local.app_tier_prefix, 4, 0)}"
  security_list_ids   = ["${oci_core_security_list.pbspro.id}"]
  vcn_id              = "${oci_core_virtual_network.pbspro.id}"
  route_table_id      = "${oci_core_route_table.private.id}"
}
