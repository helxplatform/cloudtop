#!/usr/bin/env python
import sys
import os
import time
import docker
import pytest

def pytest_addoption(parser):
    parser.addoption("--image", action="store", default="default image")
    parser.addoption("--user", action="store", default="default user")
    parser.addoption("--passwd", action="store", default="default image")
