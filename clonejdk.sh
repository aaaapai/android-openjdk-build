#!/bin/bash
set -euo pipefail

git clone -b jdk-17.0.11+1_adopt --depth 1 https://github.com/adoptium/jdk17u openjdk
