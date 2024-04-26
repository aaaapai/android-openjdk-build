# Use the old NDK r10e to not get internal compile error at (still?)
# https://github.com/PojavLauncherTeam/openjdk-multiarch-jdk8u/blob/aarch64-shenandoah-jdk8u272-b10/jdk/src/share/native/sun/java2d/loops/GraphicsPrimitiveMgr.c
export NDK_VERSION=r25c

if [[ -z "$BUILD_FREETYPE_VERSION" ]]
then
  export BUILD_FREETYPE_VERSION="2.13.2"
fi

if [[ -z "$JDK_DEBUG_LEVEL" ]]
then
  export JDK_DEBUG_LEVEL=release
fi

if [[ "$TARGET_JDK" == "aarch64" ]]
then
  export TARGET_SHORT=arm64
else
  export TARGET_SHORT=$TARGET_JDK
fi

if [[ -z "$JVM_VARIANTS" ]]
then
  export JVM_VARIANTS=server
fi

export JVM_PLATFORM=linux
# Set NDK
export API=21

# Runners usually ship with a recent NDK already
if [[ -z "$ANDROID_NDK_HOME" ]]
then
  export ANDROID_NDK_HOME=$PWD/android-ndk-$NDK_VERSION
fi

export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64

export ANDROID_INCLUDE=$TOOLCHAIN/sysroot/usr/include

export CPPFLAGS="-I$ANDROID_INCLUDE -I$ANDROID_INCLUDE/$TARGET" # -I/usr/include -I/usr/lib
if [[ "$TARGET_JDK" == "arm" ]]
then
  export LDFLAGS="$TOOLCHAIN/sysroot/usr/lib/${TARGET-2}/${API}"
else
  export LDFLAGS="$TOOLCHAIN/sysroot/usr/lib/${TARGET}/${API}"
fi
export thecc=$TOOLCHAIN/bin/${TARGET}${API}-clang
export thecxx=$TOOLCHAIN/bin/${TARGET}${API}-clang++

# Configure and build.
export NM=$TOOLCHAIN/bin/llvm-nm
export CC=$PWD/android-wrapped-clang
export CXX=$PWD/android-wrapped-clang++
export AR=$TOOLCHAIN/bin/llvm-ar
export AS=$TOOLCHAIN/bin/llvm-as
export LD=$TOOLCHAIN/bin/ld
export OBJCOPY=$TOOLCHAIN/bin/llvm-objcopy
export OBJDUMP=$TOOLCHAIN/bin/llvm-objdump
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip
export LINK=$TOOLCHAIN/bin/llvm-link

