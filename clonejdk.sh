#!/bin/bash
set -e
if [[ "$TARGET_JDK" == "arm" ]]; then
git clone --depth 1 https://github.com/openjdk/aarch32-port-jdk8u openjdk
else
git clone -b dragonwell_extended-8.19.20 --depth 1 https://github.com/dragonwell-project/dragonwell8 openjdk
fi
