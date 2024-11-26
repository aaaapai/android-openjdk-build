#!/bin/bash
set -e
. setdevkitpath.sh

export FREETYPE_DIR=$PWD/freetype-$BUILD_FREETYPE_VERSION/build_android-$TARGET_SHORT
export CUPS_DIR=$PWD/cups
export CFLAGS+=" -DLE_STANDALONE -Wno-error=int-conversion -Wno-error=implicit-function-declaration" # -I$FREETYPE_DIR -I$CUPS_DI
if [[ "$TARGET_JDK" == "arm" ]]
then
  export CFLAGS+=" -O3 -D__thumb__"
else
  if [[ "$TARGET_JDK" == "x86" ]]; then
     export CFLAGS+=" -O3 -mstackrealign"
  else
     export CFLAGS+=" -O3"
  fi
fi

# if [ "$TARGET_JDK" == "aarch32" ] || [ "$TARGET_JDK" == "aarch64" ]
# then
#   export CFLAGS+=" -march=armv7-a+neon"
# fi

# It isn't good, but need make it build anyways
# cp -R $CUPS_DIR/* $ANDROID_INCLUDE/

# cp -R /usr/include/X11 $ANDROID_INCLUDE/
# cp -R /usr/include/fontconfig $ANDROID_INCLUDE/

chmod +x android-wrapped-clang
chmod +x android-wrapped-clang++
ln -s -f /usr/include/X11 $ANDROID_INCLUDE/
ln -s -f /usr/include/fontconfig $ANDROID_INCLUDE/
platform_args="--with-toolchain-type=gcc \
  --with-freetype-include=$FREETYPE_DIR/include/freetype2 \
  --with-freetype-lib=$FREETYPE_DIR/lib \
  OBJDUMP=${OBJDUMP} \
  STRIP=${STRIP} \
  NM=${NM} \
  AR=${AR} \
  OBJCOPY=${OBJCOPY} \
  CXXFILT=${CXXFILT} \
  "
AUTOCONF_x11arg="--x-includes=$ANDROID_INCLUDE/X11"
AUTOCONF_EXTRA_ARGS+="OBJCOPY=$OBJCOPY \
  AR=$AR \
  STRIP=$STRIP \
  "

export CFLAGS+=" -mllvm -polly -DANDROID"
export LDFLAGS+=" -L$PWD/dummy_libs -Wl,--undefined-version" 

# Create dummy libraries so we won't have to remove them in OpenJDK makefiles
mkdir -p dummy_libs
ar cr dummy_libs/libpthread.a
ar cr dummy_libs/librt.a
ar cr dummy_libs/libthread_db.a

# fix building libjawt
ln -s -f $CUPS_DIR/cups $ANDROID_INCLUDE/

cd openjdk

# Apply patches
git reset --hard
git apply --reject --whitespace=fix ../patches/jdk17u_android.diff || echo "git apply failed (Android patch set)"

# rm -rf build

#   --with-extra-cxxflags="$CXXFLAGS -Dchar16_t=uint16_t -Dchar32_t=uint32_t" \
#   --with-extra-cflags="$CPPFLAGS" \

bash ./configure \
    --with-version-pre=" " \
    --with-conf-name="android-linux-aarch64" \
    --with-toolchain-path="$toolchain" \
    --with-sysroot="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot" \
    --host=aarch64-linux-android \
    --target=aarch64-linux-android \
    --with-extra-cflags="$CFLAGS" \
    --with-extra-cxxflags="$CFLAGS" \
    --with-extra-ldflags="$LDFLAGS" \
    --disable-precompiled-headers \
    --disable-warnings-as-errors \
    --enable-option-checking=fatal \
    --enable-headless-only \
    --with-jvm-variants=$JVM_VARIANTS \
    --with-jvm-features=-dtrace,-zero,-vm-structs,-epsilongc \
    --with-cups-include=$CUPS_DIR \
    --with-devkit=$TOOLCHAIN \
    --with-native-debug-symbols=external \
    --with-debug-level=$JDK_DEBUG_LEVEL \
    --with-fontconfig-include=$ANDROID_INCLUDE \
    $AUTOCONF_x11arg $AUTOCONF_EXTRA_ARGS \
    --x-libraries=/usr/lib \
        $platform_args || \
error_code=$?
if [[ "$error_code" -ne 0 ]]; then
  echo "\n\nCONFIGURE ERROR $error_code , config.log:"
  cat config.log
  exit $error_code
fi

jobs=$(nproc)

echo Running ${jobs} jobs to build the jdk

cd build/${JVM_PLATFORM}-${TARGET_JDK}-${JVM_VARIANTS}-${JDK_DEBUG_LEVEL}
make JOBS=$jobs images || \
error_code=$?
if [[ "$error_code" -ne 0 ]]; then
  echo "Build failure, exited with code $error_code. Trying again."
  make JOBS=$jobs images
fi
