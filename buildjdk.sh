#!/bin/bash
set -e
. setdevkitpath.sh

if [[ "$TARGET_JDK" == "arm" ]]
then
  export TARGET_JDK=aarch32
  export TARGET_PHYS=aarch32-linux-androideabi
  export JVM_VARIANTS=client
else
  export TARGET_PHYS=$TARGET
fi

export FREETYPE_DIR=$PWD/freetype-$BUILD_FREETYPE_VERSION/build_android-$TARGET_SHORT
export CUPS_DIR=$PWD/cups-2.2.4
export CFLAGS+=" -DLE_STANDALONE" # -I$FREETYPE_DIR -I$CUPS_DI

# if [[ "$TARGET_JDK" == "aarch32" ]] || [[ "$TARGET_JDK" == "aarch64" ]]
# then
#   export CFLAGS+=" -march=armv7-a+neon"
# fi

# It isn't good, but need make it build anyways
# cp -R $CUPS_DIR/* $ANDROID_INCLUDE/

# cp -R /usr/include/X11 $ANDROID_INCLUDE/
# cp -R /usr/include/fontconfig $ANDROID_INCLUDE/

export CFLAGS+=" -O3 -D__ANDROID__"

ln -s -f /usr/include/X11 $ANDROID_INCLUDE/
ln -s -f /usr/include/fontconfig $ANDROID_INCLUDE/
AUTOCONF_x11arg="--x-includes=$ANDROID_INCLUDE/X11"

export LDFLAGS+=" -L`pwd`/dummy_libs"

# Create dummy libraries so we won't have to remove them in OpenJDK makefiles
mkdir -p dummy_libs
ar cru dummy_libs/libpthread.a
ar cru dummy_libs/libthread_db.a

# fix building libjawt
ln -s -f $CUPS_DIR/cups $ANDROID_INCLUDE/

#FREEMARKER=$PWD/freemarker-2.3.8/lib/freemarker.jar

cd openjdk

# Apply patches
git reset --hard
git apply --reject --whitespace=fix ../patches/jdk8u_android.diff || echo "git apply failed (universal patch set)"
git apply --reject --whitespace=fix ../patches/ipv6_support.diff || echo "git apply failed (universal patch set)"
git apply --reject --whitespace=fix ../patches/jdk8u_android_distags.diff || echo "git apply failed (universal patch set)"
if [ "$TARGET_JDK" != "aarch32" ]; then
   git apply --reject --whitespace=fix ../patches/jdk8u_android_main.diff || echo "git apply failed (main non-universal patch set)"
else
   git apply --reject --whitespace=fix ../patches/jdk8u_android_aarch32.diff || echo "git apply failed (aarch32 non-universal patch set)"
fi
if [[ "$TARGET_JDK" == "x86" ]]; then
   git apply --reject --whitespace=fix ../patches/jdk8u_android_page_trap_fix.diff || echo "git apply failed (x86 page trap fix)"
fi

#   --with-extra-cxxflags="$CXXFLAGS -Dchar16_t=uint16_t -Dchar32_t=uint32_t" \
#   --with-extra-cflags="$CPPFLAGS" \
#   --with-sysroot="$(xcrun --sdk iphoneos --show-sdk-path)" \

# Let's print what's available
# bash configure --help

#   --with-freemarker-jar=$FREEMARKER \
#   --with-toolchain-type=clang \
#   --with-native-debug-symbols=none \
bash ./configure \
    --openjdk-target=$TARGET_PHYS \
    --with-extra-cflags="$CFLAGS" \
    --with-extra-cxxflags="$CFLAGS" \
    --with-extra-ldflags="$LDFLAGS" \
    --enable-option-checking=fatal \
    --with-jdk-variant=normal \
    --with-jvm-variants="${JVM_VARIANTS/AND/,}" \
    --with-cups-include=$CUPS_DIR \
    --with-devkit=$TOOLCHAIN \
    --with-debug-level=$JDK_DEBUG_LEVEL \
    --with-fontconfig-include=$ANDROID_INCLUDE \
    --with-freetype-lib=$FREETYPE_DIR/lib \
    --with-freetype-include=$FREETYPE_DIR/include/freetype2 \
    $AUTOCONF_x11arg $AUTOCONF_EXTRA_ARGS \
    --x-libraries=/usr/lib \
        $platform_args || \
error_code=$?
if [[ "$error_code" -ne 0 ]]; then
  echo "\n\nCONFIGURE ERROR $error_code , config.log:"
  cat config.log
  exit $error_code
fi

cd build/${JVM_PLATFORM}-${TARGET_JDK}-normal-${JVM_VARIANTS}-${JDK_DEBUG_LEVEL}
make JOBS=4 images || \
error_code=$?
if [[ "$error_code" -ne 0 ]]; then
  echo "Build failure, exited with code $error_code. Trying again."
  make JOBS=4 images
fi
