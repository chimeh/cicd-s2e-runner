#!/bin/bash
################################################################################
##  File:  homebrew.sh
##  Desc:  Installs the Homebrew on Linux
################################################################################

# Source the helpers
source $HELPER_SCRIPTS/document.sh
source $HELPER_SCRIPTS/etc-environment.sh

sudo su linuxbrew
git clone --depth 1 https://github.com/Homebrew/brew ~/.linuxbrew/homebrew


# Update /etc/environemnt
## Put HOMEBREW_* variables
~/.linuxbrew/homebrew/brew shellenv|grep 'export HOMEBREW'|sed -E 's/^export (.*);$/\1/' | sudo tee -a /etc/environment
# add brew executables locations to PATH
brew_path=$(~/.linuxbrew/homebrew/brew shellenv|grep  '^export PATH' |sed -E 's/^export PATH="([^$]+)\$.*/\1/')
appendEtcEnvironmentPath "$brew_path"

# Validate the installation ad hoc
echo "Validate the installation reloading /etc/environment"
reloadEtcEnvironment

if ! command -v brew; then
    echo "brew was not installed"
    exit 1
fi

# Document the installed version
echo "Document the installed version"
DocumentInstalledItem "Homebrew on Linux ($(brew -v 2>&1))"
