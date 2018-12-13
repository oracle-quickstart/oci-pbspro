#!/bin/bash
#To start PBS Pro server
sudo systemctl start pbs
sudo systemctl status pbs

if [ -z "${execution_ips}" ]; then
	echo "No execution IPs passed in, nothing to configure."
	exit
fi

IFS=' ' read -r -a ips <<< "${execution_ips}"
IFS=' ' read -r -a host_names <<< "${execution_host_names}"

#To configure /etc/hosts
for index in "$${!ips[@]}"
do
	if [ -n "$(grep $${ips[index]} /etc/hosts)" ]; then
		echo "Host $${host_names[index]} is already added to /etc/hosts."
    else
    	echo "Adding $${host_names[index]} to /etc/hosts."
    	sudo -s bash -c "echo '$${ips[index]} $${host_names[index]}' >> /etc/hosts"
    fi
done

#To add execution hosts to the cluster
echo "Execution hostnames: ${execution_host_names}"
for host_name in "$${host_names[@]}"
do
	if pbsnodes -a 2>&1 | grep -w "$host_name" &> /dev/null; then
		echo "Node $host_name is already added to the cluster."
	else
		echo "Adding node $host_name to the cluster."
		sudo /opt/pbs/bin/qmgr -c "create node $host_name"		
	fi
done

#To print PBS nodes
pbsnodes -a
