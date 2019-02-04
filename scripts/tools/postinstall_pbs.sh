#!/bin/bash

set -x

usage() {
    echo -e "\nUsage: `basename $0` <node_type>. Run as root."
    echo -e "\tnode_type: control, execution"
}

if [[ $# -ne 1 ]]; then
        usage
        exit 1
fi

if [ `whoami` != "root" ]; then
        echo "Must be root. Exit."
        exit 1
fi

export TF_REPO="https://releases.hashicorp.com/terraform/0.11.10/terraform_0.11.10_linux_amd64.zip"
export OCI_PLUGIN_REPO="https://github.com/terraform-providers/terraform-provider-oci/archive/v3.7.0.tar.gz"
export AGENT_HOME="/opt/tools/agent"
export TOOLS_HOME="/opt/tools"

function deploy_master_tools() {
    #Install Terraform
    mkdir -p $TOOLS_HOME/terrafrom
    cd $TOOLS_HOME/terrafrom
    wget --quiet $TF_REPO
    unzip terraform_*.zip
    #Install OCI plugin
    wget --quiet $OCI_PLUGIN_REPO
    tar xvzf *.tar.gz
    mkdir -p /root/.terraform.d/plugins
    cp -pR terraform-provider-oci*/* /root/.terraform.d/plugins/
    echo "export PATH=\$PATH:$TOOLS_HOME/terrafrom" >> /root/.bash_profile
    echo "export PATH=\$PATH:$TOOLS_HOME/terrafrom" >> /home/opc/.bash_profile
}

function deploy_agent() {
    mkdir -p $AGENT_HOME
    mkdir -p $AGENT_HOME/image

    mv /home/opc/tools/scaleout.py $AGENT_HOME/
    mv /home/opc/tools/autoscale.sh $AGENT_HOME/
    mv /home/opc/tools/myjob.sh $AGENT_HOME/
    mv /home/opc/tools/config_cluster.sh $AGENT_HOME/

    chmod auo+x $AGENT_HOME/autoscale.sh
    chmod auo+x $AGENT_HOME/config_cluster.sh

    cp /home/opc/terraform.tfvars.template $AGENT_HOME/image/
    cat >>$AGENT_HOME/image/terraform.tfvars.template <<EOF

ssh_authorized_keys = "/home/opc/tmp.key.pub"
scale_num = "VM"
execution_display_name = "NAME"
EOF
    mv /home/opc/tools/autoscale.tf $AGENT_HOME/image/
    mv /home/opc/oci_api_key.pem $AGENT_HOME/image/
    chmod 600 $AGENT_HOME/image/oci_api_key.pem
    chown -R opc:opc $AGENT_HOME
}

function start_agent() {
    #su - opc
    #/usr/bin/python /opt/tools/agent/scaleout.py > /opt/tools/agent/scaleout.log &
    sudo su - root -c '/usr/bin/python /opt/tools/agent/scaleout.py > /opt/tools/agent/scaleout.log'
    ps -ef | grep scaleout

}

if [ "$1" = "control" ]; then
    echo "execution IPs: "
    echo ${execution_ips}

    echo "`date`: Install tools on master host."
    deploy_master_tools

    echo "`date`: Deploy Agent."

    #Deploy agent for auto scale
    deploy_agent

    #echo "`date`: Start Agent."
    start_agent
fi

if [ "$1" = "execution" ]; then
    echo "`date`: Post config PBSPro on execution host."
    #post_config
fi

echo "`date`:`basename $0` done."
