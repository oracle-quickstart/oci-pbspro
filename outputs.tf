output "server_public_ip" {
  value = "${module.pbspro_server.public_ip}"
}

output "server_private_ip" {
  value = "${module.pbspro_server.private_ip}"
}

output "execution_public_ips" {
  value = "${module.pbspro_execution.public_ips}"
}

output "execution_private_ips" {
  value = "${module.pbspro_execution.private_ips}"
}
