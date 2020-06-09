#!/usr/bin/env python
import sys
import os
import time
import docker
import pytest

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


def main():

   image = image()
   user = user()
   passwd = passwd()

   assert test_cloudtop_init(image, user, passwd) == True 
