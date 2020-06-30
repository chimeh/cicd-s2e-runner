#!/bin/bash

# Source the helpers for use with the script
source $HELPER_SCRIPTS/document.sh

yum install -y python3-devel python3-pip python3-setuptools  yamllint
yum install -y python2-devel python2-pip

echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "Python"
DocumentInstalledItemIndent "Python ($(python --version 2>&1))"
DocumentInstalledItemIndent "pip ($(pip --version))"
DocumentInstalledItemIndent "Python3 ($(python3 --version))"
DocumentInstalledItemIndent "pip3 ($(pip3 --version))"