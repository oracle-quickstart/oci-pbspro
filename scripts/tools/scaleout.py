#!/usr/bin/python
import math
import time
import commands
import os
import random
import re

agent_home = "/opt/tools/agent/"

def autoScale():
    # get all queuing job info
    (status, output) = commands.getstatusoutput('qstat -s | grep "Q" | grep -v "Queue"')
    if(output == ""):
	#print("No job pending")
	return
    print("\n######### Pending queue info ###########")
    print(output)

    with open("tmp.txt", "w") as text_file:
        text_file.write(output)

    (status, joblist) = commands.getstatusoutput("awk '{print $1}' tmp.txt")
    #print("\njoblist info is: ")
    #print(joblist + "\n")
    job_list = joblist.split("\n")

    for i in range(len(job_list)):
        
	# use each job id to find corresponding ncpus/nodes infomation
	(status, jobid) = commands.getstatusoutput("qstat -f | sed -n '/" + job_list[i] + "/,/project/p' | grep 'Job Id:'")
	job_id = jobid.split(": ",1)[1]
	print("\njob_id=" + job_id)
        (status, reqcpu) = commands.getstatusoutput("qstat -f | sed -n '/" + job_id + "/,/project/p' | grep 'Resource_List.ncpus'")        
        request_ncpus = int(reqcpu.split("= ",1)[1])
	(status, reqnode) = commands.getstatusoutput("qstat -f | sed -n '/" + job_id + "/,/project/p' | grep 'Resource_List.nodect'")        
        request_nodes = int(reqnode.split("= ",1)[1])
	request_ncpus_per_node = request_ncpus/request_nodes
        print ("request_nodes=" + str(request_nodes) + ", request_ncpus_per_node=" + str(request_ncpus_per_node))
	if(request_ncpus_per_node > 8):
	    (status, output) = commands.getstatusoutput('qdel ' + job_id)
            print("ncpus_per_node greater than 8 is currently not supported, job is removed from queue.")
	    continue

	# check current culster resource and see if there's enough resource to run current queuing job
	resource_list = list(getCurResource())
	#print("resource_list: " + str(resource_list))
	assign_list = []
	for j in range(len(resource_list)):
	    #print("current resource: " + str(resource_list[j]))
	    if(resource_list[j] >= request_ncpus_per_node):
		assign_list.append(resource_list[j])
		if (len(assign_list) >= request_nodes):
		    print("assign_list: " + str(assign_list) + ", request is satistied, no need to scale.")
		    break
	if(len(assign_list) < request_nodes):
	    scale_num = request_nodes - len(assign_list) 
	    print(str(scale_num) + " nodes of at least " + str(request_ncpus_per_node) + " cpus per node need to be scaled.")
	    shape = ""
            if(request_ncpus_per_node <= 2):
	        shape = "VM.Standard2.1"
	    elif(request_ncpus_per_node <= 4):
		shape = "VM.Standard2.2"
	    else:
		shape = "VM.Standard2.4"
	    provisionVM(scale_num,shape)


def getCurResource():
    reslist = []
    (status, pbsnodes) = commands.getstatusoutput("pbsnodes -a")
    for line in pbsnodes.splitlines():
        if ("resources_available.ncpus" in line):
            #print("line: " + line)
            reslist.append(int(line.split("= ",1)[1]))
    return reslist
		 

# Clean up Queue:
def cleanUpQueue():
    #print("start to clean up queue!")
    (status, output) = commands.getstatusoutput('qstat -s | grep "Q" | grep -v "Queue"')
    print("pending queue info is: " + output)

    with open("tmp.txt", "w") as text_file:
        text_file.write(output)

    (status, joblist) = commands.getstatusoutput("awk '{print $1}' tmp.txt")
    print("joblist info is: " + joblist)
    list = joblist.split("\n")
    for i in range(len(list)):
        (status, output) = commands.getstatusoutput('qdel ' + list[i])


# touch a file
def touch(path):
    with open(path, 'a'):
        os.utime(path, None)


# Provision VM
#1. Check lock file
#2. count how many PENDS CPU are there
#3. figure how many VM we should provision
#4. Provision VM by terraform command
#5. Wait 5 mins , remove the lock file
def provisionVM(num,shape):
    lock_file = agent_home + '/lock'
    if os.path.exists(lock_file):

       print('###########################################')
       print('# lock file existing, do nothing......... #')
       print('###########################################\n\t')
       return
    else:
       print('#########################################################')
       print('# Begin provision %s VM(s),generate a lock file........  #'%num)
       print('#########################################################\n\t')
       touch(lock_file)

    target_file = agent_home + '/image/terraform.tfvars'
    template_file = agent_home + '/image/terraform.tfvars.template'
    rep(template_file,target_file,str(random.random()),str(num),shape)

    commands.getstatusoutput("rm -rf " + agent_home + "/image/terraform.tfstate")

    print('#######################################')
    print('# Begin to execute terraform command. #')
    print('#######################################\n\t')
    scale_path = agent_home + '/image'
    (status, output) = commands.getstatusoutput("cd " + scale_path + " && terraform init && terraform apply -auto-approve")
    print(output)
    print(status)

    if status == 0:
        print('The terraform apply is successfully. Wait 5 minutes.')
        time.sleep(300)
    #print('The current CPU number is' ,str(getCurCPU()))
    os.remove(lock_file)

	
#Replace the terraform variables
def rep(template_file,target_file,newStr1,newStr2,vmshape):
    if os.path.exists(target_file):
       os.remove(target_file)

    template = file(template_file,'r')
    target = file(target_file, 'w')
    newStr1 = newStr1.replace(".", "")

    for line in template.readlines():
       target.write(line.replace('NAME','PBS-'+newStr1).replace('VM',newStr2))
    
    target.write('execution_shape = "' + vmshape + '"')
    template.close()
    target.close()


def main():
    interval = 10     # interval time
    print("Agent is checking for scale demand every " + str(interval) + " second(s)...")
    while(True):
        autoScale()
	time.sleep(interval)


if __name__ == '__main__' :
    main()

