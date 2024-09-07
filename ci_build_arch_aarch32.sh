#!/bin/bash
set -e

export TARGET=arm-linux-androideabi
export TARGET_1=armv7a-linux-androideabi
export TARGET_JDK=arm

bash ci_build_global.sh

