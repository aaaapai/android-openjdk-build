#!/bin/bash
set -e

. setdevkitpath.sh

targetpath=openjdk/build/${JVM_PLATFORM}-${TARGET_JDK}-${JVM_VARIANTS}-${JDK_DEBUG_LEVEL}

rm -rf dizout jreout jdkout dSYM-temp
mkdir -p dizout dSYM-temp/{lib,bin}

cp freetype-$BUILD_FREETYPE_VERSION/build_android-$TARGET_SHORT/lib/libfreetype.so $targetpath/images/jdk/lib/

cp -r $targetpath/images/jdk jdkout

# JDK no longer create separate JRE image, so we have to create one manually.
#mkdir -p jreout/bin
#cp jdkout/bin/{java,jfr,keytool,rmiregistry} jreout/bin/
#cp -r jdkout/{conf,legal,lib,man,release} jreout/
#rm jreout/lib/src.zip

if [[ "$TARGET_JDK" == "aarch64" ]] || [[ "$TARGET_JDK" == "x86_64" ]]; then
   echo "Building for aarch64 or x86_64, introducing JVMCI module"
   export EXTRA_JLINK_OPTION=,jdk.internal.vm.ci
fi

# Produce the jre equivalent from the jdk (https://blog.adoptium.net/2021/10/jlink-to-produce-own-runtime/)
export JLINK_STRIP_ARG="--strip-native-debug-symbols=exclude-debuginfo-files:objcopy=${OBJCOPY}"

$targetpath/buildjdk/jdk/bin/jlink \
--module-path=jdkout/jmods \
--add-modules java.base,java.compiler,java.datatransfer,java.desktop,java.instrument,java.logging,java.management,java.management.rmi,java.naming,java.net.http,java.prefs,java.rmi,java.scripting,java.se,java.security.jgss,java.security.sasl,java.sql,java.sql.rowset,java.transaction.xa,java.xml,java.xml.crypto,jdk.accessibility,jdk.charsets,jdk.crypto.cryptoki,jdk.crypto.ec,jdk.dynalink,jdk.httpserver,jdk.jdwp.agent,jdk.jfr,jdk.jsobject,jdk.localedata,jdk.management,jdk.management.agent,jdk.management.jfr,jdk.naming.dns,jdk.naming.rmi,jdk.net,jdk.nio.mapmode,jdk.sctp,jdk.security.auth,jdk.security.jgss,jdk.unsupported,jdk.xml.dom,jdk.zipfs,jdk.incubator.vector$EXTRA_JLINK_OPTION \
--output jreout \
$JLINK_STRIP_ARG \
--no-man-pages \
--no-header-files \
--release-info=jdkout/release \
--compress=0

cp freetype-$BUILD_FREETYPE_VERSION/build_android-$TARGET_SHORT/lib/libfreetype.so jreout/lib/
cp freetype-$BUILD_FREETYPE_VERSION/build_android-$TARGET_SHORT/lib/libfreetype.so jdkout/lib/

# mv jreout/lib/${TARGET_JDK}/libfontmanager.diz jreout/lib/${TARGET_JDK}/libfontmanager.diz.keep
# find jreout -name "*.debuginfo" | xargs -- rm
# mv jreout/lib/${TARGET_JDK}/libfontmanager.diz.keep jreout/lib/${TARGET_JDK}/libfontmanager.diz

#find jdkout -name "*.debuginfo" | xargs -- rm
find jdkout -name "*.debuginfo" -exec mv {}   dizout/ \;

find jdkout -name "*.dSYM"  | xargs -- rm -rf

#TODO: fix .dSYM stuff
