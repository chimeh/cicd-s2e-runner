#!/bin/bash

THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source ${SCRIPT_DIR}/0helper-document.sh

# Install LTS Node.js and related build tools
cd ~
git clone  --branch v0.35.3 --depth 1 https://github.com/nvm-sh/nvm.git .nvm
cd .nvm
echo 'export NVM_DIR="$HOME/.nvm"' >/etc/profile.d/nvm.sh
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm'  >>/etc/profile.d/nvm.sh
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >>/etc/profile.d/nvm.sh

. nvm.sh
nvm install lts/dubnium 

npm install -g grunt gulp n parcel-bundler typescript
npm install -g --save-dev webpack webpack-cli
npm install -g npm


# Install Yarn repository and key
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo

# Install yarn
yum install -y yarn

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
