#!/bin/bash
set -e
. setdevkitpath.sh

export FREETYPE_DIR=$PWD/freetype-$BUILD_FREETYPE_VERSION/build_android-$TARGET_SHORT
export CUPS_DIR=$PWD/cups

if [[ "$TARGET_JDK" == "arm" ]]
then
  export CFLAGS+=" -D__thumb__"
else
  if [[ "$TARGET_JDK" == "x86" ]]; then
     export CFLAGS+=" -mstackrealign"
  fi
fi

if [[ "$TARGET_JDK" == "aarch64" ]]
then
   export CFLAGS+=" -march=armv8-a+simd+crc+fp16+dotprod+lse"
fi

ln -s -f /usr/include/X11 $ANDROID_INCLUDE/
ln -s -f /usr/include/fontconfig $ANDROID_INCLUDE/
platform_args="--with-toolchain-type=clang \
  --with-freetype-include=$FREETYPE_DIR/include/freetype2 \
  --with-freetype-lib=$FREETYPE_DIR/lib \
  OBJDUMP=${OBJDUMP} \
  STRIP=${STRIP} \
  NM=${NM} \
  AR=${AR} \
  BUILD_NM=${NM} \
  BUILD_AR=${AR} \
  BUILD_STRIP=$STRIP \
  BUILD_OBJCOPY=$OBJCOPY \
  BUILD_AS="$AS" \
  OBJCOPY=${OBJCOPY} \
  CXXFILT=${CXXFILT} \
  LD=$TOOLCHAIN/bin/ld.lld \
  "

if [[ "$TARGET_JDK" == "x86" ]]; then
    platform_args+="--build=x86_64-unknown-linux-gnu \
    "
fi

AUTOCONF_x11arg="--x-includes=$ANDROID_INCLUDE/X11"
AUTOCONF_EXTRA_ARGS+="OBJCOPY=$OBJCOPY \
  AR=$AR \
  STRIP=$STRIP \
  "

#no error
export CFLAGS+=" -DANDROID -D__ANDROID__=1 -DLE_STANDALONE -Wno-int-conversion -Wno-error=implicit-function-declaration"

export CFLAGS+=" -O3 -mllvm -hot-cold-split=true -fwhole-program-vtables -fdata-sections -ffunction-sections -fmerge-all-constants -ftree-vectorize -fomit-frame-pointer -fvectorize -fslp-vectorize -fno-semantic-interposition -fopenmp -pipe -integrated-as"
export LDFLAGS+=" -fuse-ld=lld -Wl,--strip-all -fvisibility=hidden -Wl,-Bsymbolic -Wl,-O3 -Wl,--sort-common -Wl,--relax -Wl,--gc-sections -Wl,--as-needed -fopenmp -l:libomp.a"
#LTO
export CFLAGS+=" -flto=auto -fno-emulated-tls"
export LDFLAGS+=" -flto=auto -Wl,--lto-O3 -Wl,-plugin-opt=-emulated-tls=0"
#polly
export CFLAGS+=" -mllvm -polly -mllvm -polly-vectorizer=stripmine -mllvm -polly-invariant-load-hoisting -mllvm -polly-run-inliner -mllvm -polly-run-dce -mllvm -polly-parallel -mllvm -polly-scheduling=static -mllvm -polly-detect-keep-going -mllvm -polly-ast-use-context -mllvm -polly-omp-backend=LLVM -mllvm -polly-num-threads=4 -mllvm -polly-scheduling-chunksize=4"
export OMP_NUM_THREADS=4
#fast-math
export CFLAGS+=" -ffast-math -fno-finite-math-only -fno-signed-zeros -fno-trapping-math -fno-math-errno -freciprocal-math -fno-associative-math"

export LDFLAGS+=" -L$PWD/dummy_libs" 

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
git apply --reject --whitespace=fix ../patches/jdk25u_android.diff || echo "git apply failed (Android patch set)"

bash ./configure \
    --with-version-pre="" \
    --with-version-opt="" \
    --with-boot-jdk-jvmargs="-XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysActAsServerClassMachine -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:ProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000 -XX:NodeLimitFudgeFactor=8000 -XX:+UseVectorCmov -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:ThreadPriorityPolicy=1 -XX:AllocatePrefetchStyle=3 -XX:AllocatePrefetchStyle=1 -XX:+UseCriticalJavaThreadPriority -XX:+UseStringDeduplication -XX:+UseFastJNIAccessors -XX:+UseThreadPriorities" \
    --openjdk-target=$TARGET \
    --with-extra-cflags="$CFLAGS" \
    --with-extra-cxxflags="$CFLAGS" \
    --with-extra-ldflags="$LDFLAGS" \
    --disable-precompiled-headers \
    --disable-warnings-as-errors \
    --enable-option-checking=fatal \
    --enable-headless-only=yes \
    --with-jvm-variants=$JVM_VARIANTS \
    --with-jvm-features=-dtrace,-zero,-vm-structs,-epsilongc,link-time-opt,opt-size \
    --enable-linktime-gc \
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
