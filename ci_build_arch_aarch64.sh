#!/bin/bash
set -e
export TARGET=aarch64-linux-android
export TARGET_JDK=aarch64

bash ci_build_global.sh

