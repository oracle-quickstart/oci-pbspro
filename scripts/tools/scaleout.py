#!/usr/bin/python
import math
import time
import commands
import os
import random
import re

agent_home = "/opt/tools/agent/"
# Get the PENDS cpu number for normal
def getPEND():
    (status, output) = commands.getstatusoutput('qstat -s | grep "Never Run"')
    if len(output) != 0:
        print('The pending job information is: '+ output)
        required = int(re.search('\d+',re.search('R: \d+', output).group()).group())
        existing = int(re.search('\d+',re.search('A: \d+', output).group()).group())
        print("required is: " + str(required))
        print("existing is: " + str(existing))
        return int(required - existing)
    return 0


# Get all current available CPU number
def getCurCPU():
    (status, output) = commands.getstatusoutput('qstat -s')
    print('The pending job information is: '+ output)
    existing = int(re.search('\d+',re.search('A: \d+', output).group()).group())
    return int(existing)

# Clean up Queue:
def cleanUpQueue():
    print("start to clean up queue!")
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
def provisionVM(num):
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
    rep(template_file,target_file,str(random.random()),str(num))

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
def rep(template_file,target_file,newStr1,newStr2):
    if os.path.exists(target_file):
       os.remove(target_file)

    template = file(template_file,'r')
    target = file(target_file, 'w')
    newStr1 = newStr1.replace(".", "")

    for line in template.readlines():
       target.write(line.replace('NAME','PBS-'+newStr1).replace('VM',newStr2))
    template.close()
    target.close()


def main():
    interval = 1     # interval time
    shape = 4       # the number of CPUs of current shape
    scale_num = getPEND()
    print("scale_num is: " + str(scale_num))
    while(True):
      time.sleep(interval)
      scale_num = getPEND()
      prov_num = int(math.ceil(scale_num * 1.0 / shape))  # the final number of VMs to be provisioned

      print('#############################################')
      print('# the number of VMs need to be scaled is '+str(prov_num)+' #')
      print('#############################################\n\t')

      if(prov_num > 0):
         print("start")
         cleanUpQueue()
         print("end queue cleanup")
         provisionVM(prov_num)
         

if __name__ == '__main__' :
    main()
