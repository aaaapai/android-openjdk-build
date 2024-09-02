#!/bin/bash
set -e

if [[ "$TARGET_JDK" == "arm" ]]; then
  export TARGET_JDK=aarch32
fi

imagespath=openjdk/build/${JVM_PLATFORM}-${TARGET_JDK}-normal-${JVM_VARIANTS}-${JDK_DEBUG_LEVEL}/images

rm -rf dizout jreout jdkout
mkdir dizout

cp -r $imagespath/j2re-image jreout
cp -r $imagespath/j2sdk-image jdkout

if [[ "$TARGET_JDK" == "x86" ]]; then
  export TARGET_JDK=i386
fi

mv jdkout/jre/lib/${TARGET_JDK}/libfreetype.so.6 jdkout/lib/${TARGET_JDK}/libfreetype.so || echo "Move exit $?"
mv jdkout/jre/lib/libfreetype.dylib.6 jdkout/lib/libfreetype.dylib || echo "Move exit $?"
mv jreout/lib/${TARGET_JDK}/libfreetype.so.6 jreout/lib/${TARGET_JDK}/libfreetype.so || echo "Move exit $?"
mv jreout/lib/libfreetype.dylib.6 jreout/lib/libfreetype.dylib || echo "Move exit $?"

# mv jreout/lib/${TARGET_JDK}/libfontmanager.diz jreout/lib/${TARGET_JDK}/libfontmanager.diz.keep
# find jreout -name "*.diz" | xargs -- rm
# mv jreout/lib/${TARGET_JDK}/libfontmanager.diz.keep jreout/lib/${TARGET_JDK}/libfontmanager.diz

find jreout -name "*.diz" -delete
find jdkout -name "*.diz" -exec mv {} dizout/ \;
