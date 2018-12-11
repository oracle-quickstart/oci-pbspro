#!/bin/bash
component=$1
server_host_name=$2
version=18.1.3

#To install the PBS Pro
wget https://github.com/PBSPro/pbspro/releases/download/v$version/pbspro_$version.centos7.zip
unzip pbspro_$version.centos7.zip
cd pbspro_$version.centos7
sudo yum -y install pbspro-$component-$version-0.x86_64.rpm
source /etc/profile.d/pbs.sh

#To configure networking
sudo firewall-cmd --zone=public --add-port=15001-15004/tcp --permanent
sudo firewall-cmd --zone=public --add-port=17001/tcp --permanent
sudo firewall-cmd --reload
