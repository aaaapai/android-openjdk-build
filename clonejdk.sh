#!/bin/bash
set -e

git clone -b jdk25 --depth 1 https://github.com/graalvm/labs-openjdk openjdk

git clone -b master --depth 1 https://github.com/oracle/graal.git graalvm
git clone --depth 1 https://github.com/graalvm/mx.git mx

export MX_PATH=$PWD/mx
export PATH=$MX_PATH:$PATH
