variable "compartment_ocid" {
  description = "The OCID of the Compartment to create the PBS Pro instance in."
}

variable "availability_domain" {
  description = "The Availability Domain for the PBS complex."
}

variable "ssh_authorized_keys" {
  description = "Public SSH keys path to be included in the ~/.ssh/authorized_keys file for the default user on the instance."
}

variable "ssh_private_key" {
  description = "The private key path to access instances."
}

variable "server_display_name" {
  description = "The display name of the PBS Pro server."
  default     = "pbspro-server"
}

variable "server_shape" {
  description = "The shape for the PBS Pro server."
  default     = "VM.Standard1.1"
}

variable "server_image_id" {
  description = "The OCID of the image for the PBS Pro server."
}

variable "server_assign_public_ip" {
  description = "Whether the VNIC should be assigned a public IP address."
  default     = true
}

variable "server_subnet_id" {
  description = "The subnet id to host the PBS Pro server."
}

variable "execution_count" {
  description = "The number of the PBS Pro execution hosts."
  default     = 2
}

variable "execution_display_name" {
  description = "The display name of the PBS Pro execution hosts."
  default     = "pbspro-execution"
}

variable "execution_shape" {
  description = "The shape for the PBS Pro execution hosts."
  default     = "VM.Standard2.1"
}

variable "execution_image_id" {
  description = "The OCID of the image for the PBS Pro execution hosts."
}

variable "execution_assign_public_ip" {
  description = "Whether the VNIC should be assigned a public IP address."
  default     = false
}

variable "execution_subnet_id" {
  description = "The subnet id to host the PBS Pro execution hosts."
}

variable "bastion_host" {
  description = "The host of bastion."
}

variable "bastion_user" {
  description = "The user of the bastion host."
  default     = "opc"
}

variable "bastion_private_key" {
  description = "The private key path to access the bastion instance."
}
