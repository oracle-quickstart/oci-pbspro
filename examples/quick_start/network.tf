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
  display_name   = "pbspro"
}

resource "oci_core_route_table" "pbspro" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.pbspro.id}"
  display_name   = "pbspro"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.pbspro.id}"
  }
}

locals {
  tcp_protocol    = "6"
  anywhere        = "0.0.0.0/0"
  app_tier_prefix = "${cidrsubnet(var.vcn_cidr, 4, 0)}"
}

resource "oci_core_security_list" "server" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "server"
  vcn_id         = "${oci_core_virtual_network.pbspro.id}"

  egress_security_rules = [{
    protocol    = "${local.tcp_protocol}"
    destination = "${local.anywhere}"
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }

    protocol = "${local.tcp_protocol}"
    source   = "${local.anywhere}"
  },
    {
      tcp_options {
        "max" = 17001
        "min" = 17001
      }

      protocol = "${local.tcp_protocol}"
      source   = "${local.anywhere}"
    },
  ]
}

resource "oci_core_security_list" "execution" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "execution"
  vcn_id         = "${oci_core_virtual_network.pbspro.id}"

  egress_security_rules = [{
    protocol    = "${local.tcp_protocol}"
    destination = "${local.anywhere}"
  }]

  ingress_security_rules = [{
    tcp_options {
      "max" = 22
      "min" = 22
    }

    protocol = "${local.tcp_protocol}"
    source   = "${local.anywhere}"
  }]
}

resource "oci_core_subnet" "server" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[var.ad_index - 1], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "server_ad${var.ad_index}"
  dns_label           = "server"
  cidr_block          = "${cidrsubnet("${local.app_tier_prefix}", 4, 0)}"
  security_list_ids   = ["${oci_core_security_list.server.id}"]
  vcn_id              = "${oci_core_virtual_network.pbspro.id}"
  route_table_id      = "${oci_core_route_table.pbspro.id}"
  dhcp_options_id     = "${oci_core_virtual_network.pbspro.default_dhcp_options_id}"
}

resource "oci_core_subnet" "execution" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ad.availability_domains[var.ad_index - 1], "name")}"
  compartment_id      = "${var.compartment_ocid}"
  display_name        = "execution_ad${var.ad_index}"
  dns_label           = "execution"
  cidr_block          = "${cidrsubnet("${local.app_tier_prefix}", 4, 1)}"
  security_list_ids   = ["${oci_core_security_list.execution.id}"]
  vcn_id              = "${oci_core_virtual_network.pbspro.id}"
  route_table_id      = "${oci_core_route_table.pbspro.id}"
  dhcp_options_id     = "${oci_core_virtual_network.pbspro.default_dhcp_options_id}"
}
