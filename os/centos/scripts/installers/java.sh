#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))
source ${SCRIPT_DIR}/0helper-document.sh
source ${SCRIPT_DIR}/0helper-etc-environment.sh 

#jdk
yum install -y java-1.8.0-openjdk-devel

#maven
MAVEN_VERSION=3.6.3
mkdir -p /root/ts
wget -q -P /root/ts https://mirror.azure.cn/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
tar -xf /root/ts/apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt
mkdir -p /root/.m2
cp /opt/apache-maven-${MAVEN_VERSION}/conf/settings.xml /root/.m2/settings.xml
ln -sf /root/.m2/settings.xml /opt/apache-maven-${MAVEN_VERSION}/conf/settings.xml
rm -rf /root/ts
echo "M2_HOME=/opt/apache-maven-${MAVEN_VERSION}" | tee -a /etc/environment
injectpath "/opt/apache-maven-${MAVEN_VERSION}/bin"

#gradle
GRADLE_VERSION=6.2.2
mkdir -p /root/ts
wget -q -P /root/ts  https://downloads.gradle-dn.com/distributions/gradle-${GRADLE_VERSION}-all.zip
mkdir -p /opt/gradle
unzip  -qq /root/ts/gradle-${GRADLE_VERSION}-all.zip -d /opt/gradle
rm -rf /root/ts
echo "GRADLE_HOME=/opt/gradle/gradle-${GRADLE_VERSION}" | tee -a /etc/environment
injectpath "/opt/gradle/gradle-${GRADLE_VERSION}/bin"

# Run tests to determine that the software installed as expected
echo "check cmd run ok"
for cmd in gradle java javac mvn; do
    if ! command -v $cmd; then
        echo "$cmd was not installed or found on path"
        exit 1
    fi
done

DocumentInstalledItem "Java:"
DocumentInstalledItemIndent "java : $(java -version 2>&1| head -n 1)"
DocumentInstalledItemIndent "maven: $(mvn -version 2>&1| head -n 1)"
DocumentInstalledItemIndent "gradle: $(gradle -version 2>&1|egrep Gradle| head -n 1)"