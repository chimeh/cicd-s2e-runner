#!/bin/bash

# Source the helpers for use with the script
source $HELPER_SCRIPTS/document.sh
set +e
# Install GitHub CLI
url=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | jq -r '.assets[].browser_download_url|select(contains("linux") and contains("amd64") and contains(".rpm"))')
wget $url
apt install ./gh_*_linux_amd64.rpm
rm gh_*_linux_amd64.rpm

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
if ! gh --version; then
    echo "GitHub CLI was not installed"
    exit 0
fi

# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "GitHub CLI $(gh --version|awk 'FNR==1 {print $3}')"

set -e