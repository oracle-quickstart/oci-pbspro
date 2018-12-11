output "id" {
  value = "${oci_core_instance.server.id}"
}

output "public_ip" {
  value = "${oci_core_instance.server.public_ip}"
}

output "private_ip" {
  value = "${oci_core_instance.server.private_ip}"
}

output "host_name" {
  value = "${oci_core_instance.server.display_name}"
}
