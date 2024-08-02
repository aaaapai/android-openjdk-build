#!/bin/bash
set -e

unset AR AS CC CXX LD OBJCOPY RANLIB STRIP CPPFLAGS LDFLAGS
git clone --depth 1 https://github.com/termux/termux-elf-cleaner
cd termux-elf-cleaner
autoreconf --install
bash configure
make CFLAGS=-D__ANDROID_API__=${API}
cd ..

findexec() { find $1 -type f -name "*" -not -name "*.o" -exec sh -c '
    case "$(head -n 1 "$1")" in
      ?ELF*) exit 0;;
      MZ*) exit 0;;
      #!*/ocamlrun*)exit0;;
    esac
exit 1
' sh {} \; -print
}

findexec jreout | xargs -- ./termux-elf-cleaner/termux-elf-cleaner
findexec jdkout | xargs -- ./termux-elf-cleaner/termux-elf-cleaner

cp -Rf jre_override/lib/* jreout/lib/
cp -Rf jre_override/lib/* jdkout/jre/lib/

cd jreout

# Strip in place all .so files thanks to the ndk
find ./ -name '*.so' -execdir ${NDK}${NDK_PREBUILT_ARCH} {} \;

tar cJf ../jre8-${TARGET_SHORT}-`date +%Y%m%d`-${JDK_DEBUG_LEVEL}.tar.xz .

cd ../jdkout
tar cJf ../jdk8-${TARGET_SHORT}-`date +%Y%m%d`-${JDK_DEBUG_LEVEL}.tar.xz .

