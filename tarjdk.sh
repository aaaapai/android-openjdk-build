#!/bin/bash
set -e
. setdevkitpath.sh

unset AR AS CC CXX LD OBJCOPY RANLIB STRIP CPPFLAGS LDFLAGS
git clone --depth 1 https://github.com/termux/termux-elf-cleaner || true
cd termux-elf-cleaner
mkdir build
cd build
export CFLAGS=-D__ANDROID_API__=24
cmake ..
make -j4
unset CFLAGS
cd ../..

findexec() { find $1 -type f -name "*" -not -name "*.o" -exec sh -c '
    case "$(head -n 1 "$1")" in
      ?ELF*) exit 0;;
      MZ*) exit 0;;
      #!*/ocamlrun*)exit0;;
    esac
exit 1
' sh {} \; -print
}

findexec jreout | xargs -- ./termux-elf-cleaner/build/termux-elf-cleaner
findexec jdkout | xargs -- ./termux-elf-cleaner/build/termux-elf-cleaner

cp -rv jre_override/lib/* jreout/lib/ || true
cp -rv jre_override/lib/* jdkout/lib/ || true

if [ "${TARGET_SHORT}" = "arm64" ] && [ -f jreout/lib/jspawnhelper ]; then
    cp jreout/lib/jspawnhelper libjsph25.so
fi

cd jreout

# Strip
find ./ -name '*' -execdir ${TOOLCHAIN}/bin/llvm-strip {} \;

tar cJf ../jre25-${TARGET_SHORT}-`date +%Y%m%d`-${JDK_DEBUG_LEVEL}.tar.xz .

cd ../jdkout
tar cJf ../jdk25-${TARGET_SHORT}-`date +%Y%m%d`-${JDK_DEBUG_LEVEL}.tar.xz .

# Remove jreout and jdkout
cd ..
rm -rf jdkout jreout
