output "server_public_ip" {
  value = "${module.pbspro.server_public_ip}"
}

output "server_private_ip" {
  value = "${module.pbspro.server_private_ip}"
}

output "execution_public_ips" {
  value = "${module.pbspro.execution_public_ips}"
}

output "execution_private_ips" {
  value = "${module.pbspro.execution_private_ips}"
}
