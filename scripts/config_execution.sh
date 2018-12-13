#!/bin/bash
#To configuring /etc/hosts
if [ ! -n "$(grep ${server_ip} /etc/hosts)" ]; then
	echo "Adding ${server_host_name} to /etc/hosts"
	sudo -s bash -c "echo '${server_ip} ${server_domain_name} ${server_host_name}' >> /etc/hosts"
fi
cat /etc/hosts

ssh -oStrictHostKeyChecking=no opc@${server_domain_name} <<EOF
exit
EOF

#To configuring the PBS MoM
sudo sed -i "s/PBS_SERVER=.*$/PBS_SERVER=${server_host_name}/" /etc/pbs.conf
sudo sed -i "s/\$clienthost.*$/\$clienthost ${server_host_name}/" /var/spool/pbs/mom_priv/config
sudo cat /etc/pbs.conf
sudo cat /var/spool/pbs/mom_priv/config

sudo systemctl start pbs
sudo systemctl status pbs
