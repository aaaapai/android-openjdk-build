set -e

cd ../graalvm/substratevm
$MX_PATH/mx --java-home=$JAVA_HOME build
