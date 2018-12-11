variable "compartment_ocid" {
  description = "The OCID of the Compartment to create the PBS Pro instance in."
}

variable "availability_domain" {
  description = "The Availability Domain for the PBS Pro instance."
}

variable "subnet_id" {
  description = "The subnet id to host the PBS Pro instance."
}

variable "display_name" {
  description = "The display name of the PBS Pro instance."
}

variable "shape" {
  description = "The shape for the PBS Pro instance."
}

variable "assign_public_ip" {
  description = "Whether the VNIC should be assigned a public IP address."
}

variable "image_id" {
  description = "The OCID of the image."
}

variable "ssh_authorized_keys" {
  description = "Public SSH keys path to be included in the ~/.ssh/authorized_keys file for the default user on the instance."
}

variable "ssh_private_key" {
  description = "The private key path to access the PBS Pro instance."
}
