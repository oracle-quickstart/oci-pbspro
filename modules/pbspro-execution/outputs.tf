output "ids" {
  value = ["${oci_core_instance.execution.*.id}"]
}

output "public_ips" {
  value = ["${oci_core_instance.execution.*.public_ip}"]
}

output "private_ips" {
  value = ["${oci_core_instance.execution.*.private_ip}"]
}

output "host_names" {
  value = ["${oci_core_instance.execution.*.display_name}"]
}
