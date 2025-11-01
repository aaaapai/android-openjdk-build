#!/bin/bash
# https://github.com/termux/termux-packages/blob/master/disabled-packages/openjdk-9-jre-headless/build.sh
set -e

. setdevkitpath.sh

git clone --depth 1 https://github.com/LWJGL-CI/freetype
git clone --depth 1 https://github.com/OpenPrinting/cups
