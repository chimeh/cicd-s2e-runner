#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
THIS_SCRIPT="$(realpath "$(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)"/"$(basename "${BASH_SOURCE:-$0}")")"
#automatic detection TOPDIR
SCRIPT_DIR="$(dirname "$(realpath "${THIS_SCRIPT}")")"
source ${SCRIPT_DIR}/document.sh
URL='https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip'



# Set env variable for SDK Root (https://developer.android.com/studio/command-line/variables)
ANDROID_ROOT=/opt/android
ANDROID_SDK_ROOT=${ANDROID_ROOT}/sdk
echo "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}" | tee -a /etc/environment

# ANDROID_HOME is deprecated, but older versions of Gradle rely on it
echo "ANDROID_HOME=${ANDROID_SDK_ROOT}" | tee -a /etc/environment

# Create android sdk directory
mkdir -p ${ANDROID_SDK_ROOT}

# Download the latest command line tools so that we can accept all of the licenses.
# See https://developer.android.com/studio/#command-tools
curl -o ${ANDROID_ROOT}/android-sdk.zip -L ${URL}
unzip ${ANDROID_ROOT}/android-sdk.zip -d ${ANDROID_SDK_ROOT}
/bin/rm -f ${ANDROID_ROOT}/android-sdk.zip

# Add required permissions
chmod -R a+X ${ANDROID_SDK_ROOT}

# Check sdk manager installation
${ANDROID_SDK_ROOT}/tools/bin/sdkmanager --list 1>/dev/null
if [ $? -eq 0 ]
then
    echo "Android SDK manager was installed"
else
    echo "Android SDK manager was not installed"
    exit 1
fi

# Install the following SDKs and build tools, passing in "y" to accept licenses.
echo "y" | ${ANDROID_SDK_ROOT}/tools/bin/sdkmanager \
    "ndk-bundle" \
    "platform-tools" \
    "platforms;android-30" \
    "platforms;android-29" \
    "platforms;android-28" \
    "platforms;android-27" \
    "platforms;android-26" \
    "platforms;android-25" \
    "platforms;android-24" \
    "platforms;android-23" \
    "platforms;android-22" \
    "platforms;android-21" \
    "platforms;android-19" \
    "platforms;android-17" \
    "build-tools;30.0.0" \
    "build-tools;29.0.3" \
    "build-tools;29.0.2" \
    "build-tools;29.0.0" \
    "build-tools;28.0.3" \
    "build-tools;28.0.2" \
    "build-tools;28.0.1" \
    "build-tools;28.0.0" \
    "build-tools;27.0.3" \
    "build-tools;27.0.2" \
    "build-tools;27.0.1" \
    "build-tools;27.0.0" \
    "build-tools;26.0.3" \
    "build-tools;26.0.2" \
    "build-tools;26.0.1" \
    "build-tools;26.0.0" \
    "build-tools;25.0.3" \
    "build-tools;25.0.2" \
    "build-tools;25.0.1" \
    "build-tools;25.0.0" \
    "build-tools;24.0.3" \
    "build-tools;24.0.2" \
    "build-tools;24.0.1" \
    "build-tools;24.0.0" \
    "build-tools;23.0.3" \
    "build-tools;23.0.2" \
    "build-tools;23.0.1" \
    "build-tools;22.0.1" \
    "build-tools;21.1.2" \
    "build-tools;20.0.0" \
    "build-tools;19.1.0" \
    "build-tools;17.0.0" \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "extras;google;google_play_services" \
    "add-ons;addon-google_apis-google-24" \
    "add-ons;addon-google_apis-google-23" \
    "add-ons;addon-google_apis-google-22" \
    "add-ons;addon-google_apis-google-21" \
    "cmake;3.6.4111459" \
    "cmake;3.10.2.4988404" \
    "patcher;v4"

# Document what was added to the image
DocumentInstalledItem "Android:"
DocumentInstalledItemIndent "Android SDK Platform 30/29/28/27/26/25/24/23/22/21/19/17"
DocumentInstalledItemIndent "Android SDK Build-Tools 30/29/28/27/26/25/24/23/22/21/19/17"
DocumentInstalledItemIndent "Android SDK Platform-Tools $(cat ${ANDROID_SDK_ROOT}/platform-tools/source.properties 2>&1 | grep Pkg.Revision | cut -d '=' -f 2)"
DocumentInstalledItemIndent "Android Support Repository 47.0.0"
DocumentInstalledItemIndent "Android NDK $(cat ${ANDROID_SDK_ROOT}/ndk-bundle/source.properties 2>&1 | grep Pkg.Revision | cut -d ' ' -f 3)"
DocumentInstalledItemIndent "Patch Applier v4"
DocumentInstalledItemIndent "Google Play services $(cat ${ANDROID_SDK_ROOT}/extras/google/google_play_services/source.properties 2>&1 | grep Pkg.Revision | cut -d '=' -f 2)"
DocumentInstalledItemIndent "Google APIs 24/23/22/21"
DocumentInstalledItemIndent "Google Repository $(cat ${ANDROID_SDK_ROOT}/extras/google/m2repository/source.properties 2>&1 | grep Pkg.Revision | cut -d '=' -f 2)"
DocumentInstalledItemIndent "CMake $(ls ${ANDROID_SDK_ROOT}/cmake 2>&1)"

