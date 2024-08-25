#!/bin/bash
set -e

mkdir dragonwell8
wget https://github.com/dragonwell-project/dragonwell8/releases/download/dragonwell-extended-8.19.20_jdk8u412-ga/Alibaba_Dragonwell_Extended_8.19.20_x64_linux.tar.gz -O ./dragonwell8.tar.gz
tar zxf ./dragonwell8.tar.gz -C ./dragonwell8
