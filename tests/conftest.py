#!/usr/bin/env python
import sys
import os
import time
import docker
import pytest

def pytest_addoption(parser):
    parser.addoption("--image", action="store", default="default image")
    parser.addoption("--passwd", action="store", default="default image")
    parser.addoption("--port", action="store", default="8080")
    parser.addoption("--user", action="store", default="root")
