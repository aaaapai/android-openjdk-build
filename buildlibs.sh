#!/bin/bash
set -e
. setdevkitpath.sh
cd freetype-$BUILD_FREETYPE_VERSION

echo "Building Freetype"

export PATH=$TOOLCHAIN/bin:$PATH
./configure \
  --host=$TARGET \
  --prefix=${PWD}/build_android-${TARGET_SHORT} \
  LD=$TOOLCHAIN/bin/ld.lld \
  --without-zlib \
  --with-brotli=system \
  --with-png=no \
  --with-harfbuzz=no $EXTRA_ARGS \
  || error_code=$?

if [[ "$error_code" -ne 0 ]]; then
  echo "\n\nCONFIGURE ERROR $error_code , config.log:"
  cat ${PWD}/builds/unix/config.log
  exit $error_code
fi

CFLAGS="-O3 -fno-emulated-tls -fno-rtti -march=armv8-a+simd+crc+crypto+fp16" CXXFLAGS="-Ofast -fno-emulated-tls -fno-rtti -march=armv8-a+simd+crc+crypto+fp16" make -j4
make install
