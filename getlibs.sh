#!/bin/bash
# https://github.com/termux/termux-packages/blob/master/disabled-packages/openjdk-9-jre-headless/build.sh
set -e

. setdevkitpath.sh

wget https://downloads.sourceforge.net/project/freetype/freetype2/$BUILD_FREETYPE_VERSION/freetype-$BUILD_FREETYPE_VERSION.tar.gz
tar xf freetype-$BUILD_FREETYPE_VERSION.tar.gz
wget https://github.com/OpenPrinting/cups/releases/download/v${BUILD_CUPS_VERSION}/cups-${BUILD_CUPS_VERSION}-source.tar.gz
tar xf cups-${BUILD_CUPS_VERSION}-source.tar.gz
rm cups-${BUILD_CUPS_VERSION}-source.tar.gz freetype-$BUILD_FREETYPE_VERSION.tar.gz
