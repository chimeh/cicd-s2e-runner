#!/bin/bash

# Source the helpers for use with the script
source $HELPER_SCRIPTS/document.sh

# Install LTS Node.js and related build tools
curl -sL https://raw.githubusercontent.com/mklement0/n-install/stable/bin/n-install | bash -s -- -ny -
~/n/bin/n lts
npm install -g grunt gulp n parcel-bundler typescript
npm install -g --save-dev webpack webpack-cli
npm install -g npm
rm -rf ~/n

# Install Yarn repository and key
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo

# Install yarn
yum install yarn

# Run tests to determine that the software installed as expected
echo "Testing to make sure that script performed as expected, and basic scenarios work"
for cmd in node grunt gulp webpack parcel yarn; do
    if ! command -v $cmd; then
        echo "$cmd was not installed"
        exit 1
    fi
done

# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "Node.js/npm"
DocumentInstalledItemIndent "Node.js ($(node --version))"
DocumentInstalledItemIndent "Grunt ($(grunt --version))"
DocumentInstalledItemIndent "Gulp ($(gulp --version))"
DocumentInstalledItemIndent "npm ($(npm --version))"
DocumentInstalledItemIndent "Parcel ($(parcel --version))"
DocumentInstalledItemIndent "TypeScript ($(tsc --version))"
DocumentInstalledItemIndent "Webpack ($(webpack --version))"
DocumentInstalledItemIndent "Webpack CLI ($(webpack-cli --version))"
DocumentInstalledItemIndent "Yarn ($(yarn --version))"