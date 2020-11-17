#!/usr/bin/env python
import sys
import os
import time
import docker
import pytest
from subprocess import Popen, PIPE, CalledProcessError
import shlex
#  Example usage: pytest -q -s --image "heliumdatastage/cloudtop:latest" --user howard --passwd test

@pytest.fixture()
def image (pytestconfig):
   return pytestconfig.getoption("image")

@pytest.fixture()
def user (pytestconfig):
   return pytestconfig.getoption("user")

@pytest.fixture()
def passwd (pytestconfig):
   return pytestconfig.getoption("passwd")

def execute(cmd):
    with Popen(cmd, stdout=PIPE, bufsize=1, universal_newlines=True) as proc:
        # Kind of an awkward way to do this.  We just want to look at the first line of
        # output of the process, so we kill the process as soon as we get the line, then
        # we return the line.
        for line in proc.stdout:
            time.sleep(10)
            print(line, end='') 
            proc.kill()
        return line

    if proc.returncode != 0:
        raise CalledProcessError(proc.returncode, proc.args)

def test_cloudtop_init(image, user, passwd):

   envDict = {
      "USER_NAME": user,
      "VNC_PW": passwd
   }

   portDict = {
      '8080': 8080
   }

   client = docker.from_env()
   clientList = client.containers.list()

   container = client.containers.run(image,  environment=envDict,  ports=portDict, detach=True)

   # This gives the container some time to spin up so we can find the string we care 
   # about in the logs
   time.sleep(10)
   logs = container.logs()
   stringLogs = logs.decode("utf-8")
   linedLogs = stringLogs.split('\n')

   returnVal = False
   for i in range(len(linedLogs)):
      if (linedLogs[i] == "[cont-init.d] done."):
         returnVal = True
         break

   container.stop()
   client.containers.prune()
   return returnVal

def test_cloudtop_glx(image, user, passwd):

   envDict = {
      "USER_NAME": user,
      "VNC_PW": passwd
   }

   portDict = {
      '8080': 8080
   }

   client = docker.from_env()
   clientList = client.containers.list()

   container = client.containers.run(image,  environment=envDict,  ports=portDict, detach=True)

   # This gives the container some time to spin up so we can execute the command
   # about in the logs
   time.sleep(10)
   #commandProto = "/usr/local/bin/docker exec -it --user=USER ID /usr/bin/glxgears"
   commandProto = "docker exec -it --user=USER ID /usr/bin/glxgears"
   command = commandProto.replace("USER", user).replace("ID", container.id)
   print (command)

   args = shlex.split(command)
   returnVal = True

   try:
      glxOut = execute(args)
      index = glxOut.find("frames in 5.0 seconds")
    
      if (index == -1):
         returnVal = False
    
      container.stop()
      client.containers.prune()
   except: 
      container.stop()
      client.containers.prune()

   return returnVal

def main():

   image = image()
   user = user()
   passwd = passwd()

   assert test_cloudtop_init(image, user, passwd) == True 
   assert test_cloudtop_glx(image, user, passwd) == True 
