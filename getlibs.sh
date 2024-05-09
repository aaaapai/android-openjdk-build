#!/bin/bash
# https://github.com/termux/termux-packages/blob/master/disabled-packages/openjdk-9-jre-headless/build.sh
set -e

. setdevkitpath.sh

wget https://downloads.sourceforge.net/project/freetype/freetype2/$BUILD_FREETYPE_VERSION/freetype-$BUILD_FREETYPE_VERSION.tar.gz
tar xf freetype-$BUILD_FREETYPE_VERSION.tar.gz
wget https://github.com/OpenPrinting/cups/releases/download/v2.4.8/cups-2.4.8-source.tar.gz
tar xf cups-${BUILD_cups_VERSION}-source.tar.gz
rm cups-2.4.8-source.tar.gz freetype-$BUILD_FREETYPE_VERSION.tar.gz
