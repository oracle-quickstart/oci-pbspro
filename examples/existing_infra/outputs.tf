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

output "bastion_public_ip" {
  value = "${var.bastion_host}"
}

output "example_ssh_command" {
  value = "ssh -i ${var.ssh_private_key} -o ProxyCommand=\"ssh -i ${var.bastion_private_key} opc@${var.bastion_host} -W %h:%p\" opc@${module.pbspro.server_private_ip}"
}
