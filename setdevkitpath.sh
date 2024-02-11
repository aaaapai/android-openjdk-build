#!/bin/bash
set -euo pipefail

export NDK_VERSION=r25c

if [[ -z "${BUILD_FREETYPE_VERSION:-}" ]]; then
  export BUILD_FREETYPE_VERSION="2.13.2"
fi

if [[ -z "${JDK_DEBUG_LEVEL:-}" ]]; then
  export JDK_DEBUG_LEVEL=release
fi

if [[ "${TARGET_JDK:-}" == "aarch64" ]]; then
  export TARGET_SHORT=arm64
else
  export TARGET_SHORT=$TARGET_JDK
fi

if [[ -z "${JVM_VARIANTS:-}" ]]; then
  export JVM_VARIANTS=server
fi

if [[ "${BUILD_IOS:=0}" == "1" ]]; then
  export JVM_PLATFORM=macosx

  export thecc=$(xcrun -find -sdk iphoneos clang)
  export thecxx=$(xcrun -find -sdk iphoneos clang++)
  export thesysroot=$(xcrun --sdk iphoneos --show-sdk-path)
  export themacsysroot=$(xcrun --sdk macosx --show-sdk-path)

  export thehostcxx=$PWD/macos-host-cc
  export CC=$PWD/ios-arm64-clang
  export CXX=$PWD/ios-arm64-clang++
  export CXXCPP="$CXX -E"
  export LD=$(xcrun -find -sdk iphoneos ld)

  export HOTSPOT_DISABLE_DTRACE_PROBES=1

  export ANDROID_INCLUDE=$PWD/ios-missing-include
else
  export JVM_PLATFORM=linux
  # Set NDK
  export API=21
  export NDK=$PWD/android-ndk-$NDK_VERSION
  export ANDROID_NDK_ROOT=$NDK
  export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64
  export ANDROID_INCLUDE=$TOOLCHAIN/sysroot/usr/include

  export CPPFLAGS="-I$ANDROID_INCLUDE -I$ANDROID_INCLUDE/$TARGET"
  export LDFLAGS="-L$NDK/platforms/android-$API/arch-$TARGET_SHORT/usr/lib"

  export thecc=$TOOLCHAIN/bin/$TARGET$API-clang
  export thecxx=$TOOLCHAIN/bin/$TARGET$API-clang++

  # Configure and build.
  export AR=$TOOLCHAIN/bin/llvm-ar
  export CC=$thecc
  export AS=$CC
  export CXX=$thecxx
  export LD=$TOOLCHAIN/bin/ld
  export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
  export STRIP=$TOOLCHAIN/bin/llvm-strip
  export NM=$TOOLCHAIN/bin/llvm-nm
  export OBJCOPY=$TOOLCHAIN/bin/llvm-objcopy
  export OBJDUMP=$TOOLCHAIN/bin/llvm-objdump
fi
