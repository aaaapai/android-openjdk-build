#!/bin/bash
set -e

export TARGET=armv7a-linux-androideabi
export TARGET_2=arm-linux-androideabi
export TARGET_JDK=arm

bash ci_build_global.sh
