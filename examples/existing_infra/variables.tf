variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "compartment_ocid" {}
variable "ssh_authorized_keys" {}
variable "ssh_private_key" {}
variable "bastion_authorized_keys" {}
variable "bastion_private_key" {}

variable "image_ids" {
  type = "map"

  default = {
    // Oracle-provided image "Oracle-Linux-7.4-2018.02.21-1"
    // See https://docs.us-phoenix-1.oraclecloud.com/images/
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaaupbfz5f5hdvejulmalhyb6goieolullgkpumorbvxlwkaowglslq"

    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaajlw3xfie2t5t52uegyhiq2npx7bqyu4uvi2zyu3w3mqayc2bxmaa"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa7d3fsb6272srnftyi4dphdgfjf6gurxqhmv6ileds7ba3m2gltxq"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaaa6h6gj6v4n56mqrbgnosskq63blyv2752g36zerymy63cfkojiiq"
  }
}

variable "subnet_id" {
  description = "The subnet id to host the PBS Pro cluster."
}

variable "ad_index" {
  description = "The index of the availablity domain for PBS. 1, 2, or 3"
  default     = 1
}

variable "server_display_name" {
  description = "The display name of the PBS Pro server."
  default     = "pbspro-server"
}

variable "server_shape" {
  description = "The shape for the PBS Pro server."
  default     = "VM.Standard1.1"
}

variable "execution_count" {
  description = "The number of the PBS Pro execution hosts."
  default     = 1
}

variable "execution_display_name" {
  description = "The display name of the PBS Pro execution hosts."
  default     = "pbspro-execution"
}

variable "execution_shape" {
  description = "The shape for the PBS Pro execution hosts."
  default     = "VM.Standard2.1"
}

variable "bastion_host" {
  description = "The public ip of bastion host."
}

variable "bastion_user" {
  description = "The user of the bastion host."
  default     = "opc"
}
