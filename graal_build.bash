#!/bin/bash
set -e
. setdevkitpath.sh

cd ./openjdk/graal

# 用 mx 工具构建 GraalVM 组件
$MX_PATH/mx --primary-suite-path compiler --java-home=${JAVA_HOME} --tools-java-home=${JAVA_HOME} build
$MX_PATH/mx --primary-suite-path vm --java-home=${JAVA_HOME} --tools-java-home=${JAVA_HOME} build
# $MX_PATH/mx --primary-suite-path substratevm --java-home=../build/${JVM_PLATFORM}-${TARGET_JDK}-${JVM_VARIANTS}-${JDK_DEBUG_LEVEL}/buildjdk/jdk --tools-java-home=${JAVA_HOME} build
