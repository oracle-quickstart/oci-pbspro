#!/bin/bash

set -x

usage() {
    echo -e "\nRun as root."
}


export AGENT_HOME="/opt/tools/agent"
export TOOLS_HOME="/opt/tools"


cd $AGENT_HOME/init
/bin/rm -f terraform.tfstate*
terraform init
terraform apply -auto-approve
if [ $? -eq 0 ]; then
    echo "`date`: Create image successful."
    exit 0
else
    echo "`date`: Create image failed."
    exit 1
fi
