#!/bin/bash
set -e
. setdevkitpath.sh

cd ./graalvm

# 用 mx 工具构建 GraalVM 组件
$MX_PATH/mx --primary-suite-path compiler --java-home=$JAVA_HOME build

# 构建 native-image（或其它 GraalVM 组件）
$MX_PATH/mx --primary-suite-path substratevm --java-home=$JAVA_HOME build
