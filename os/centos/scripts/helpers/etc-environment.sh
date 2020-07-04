#!/bin/bash
################################################################################
##  File:  etc-environment.sh
##  Desc:  Helper functions for source and modify /etc/environment
################################################################################

# NB: sed expression use '%' as a delimiter in order to simplify handling
#     values containg slashes (i.e. directory path)
#     The values containing '%' will break the functions

THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

source /etc/profile.d/sh.local

function getEtcEnvironmentVariable {
    variable_name="$1"
    # remove `variable_name=` and possible quotes from the line
    grep "^${variable_name}=" /etc/environment |sed -E "s%^${variable_name}=\"?([^\"]+)\"?.*$%\1%"
}

function addEtcEnvironmentVariable {
    variable_name="$1"
    variable_value="$2"

    echo "$variable_name=\"$variable_value\"" | sudo tee -a /etc/environment
}

function replaceEtcEnvironmentVariable {
    variable_name="$1"
    variable_value="$2"

    # modify /etc/environemnt in place by replacing a string that begins with variable_name
    sudo sed -i -e "s%^${variable_name}=.*$%${variable_name}=\"${variable_value}\"%" /etc/environment
}

function setEtcEnvironmentVariable {
    variable_name="$1"
    variable_value="$2"

    if grep "$variable_name" /etc/environment > /dev/null; then
        replaceEtcEnvironmentVariable $variable_name $variable_value
    else
        addEtcEnvironmentVariable $variable_name $variable_value
    fi
}

function prependEtcEnvironmentVariable {
    variable_name="$1"
    element="$2"
    # TODO: handle the case if the variable does not exist
    existing_value=$(getEtcEnvironmentVariable "${variable_name}")
    setEtcEnvironmentVariable "${variable_name}" "${element}:${existing_value}"
}

function appendEtcEnvironmentVariable {
    variable_name="$1"
    element="$2"
    # TODO: handle the case if the variable does not exist
    existing_value=$(getEtcEnvironmentVariable "${variable_name}")
    setEtcEnvironmentVariable "${variable_name}" "${existing_value}:${element}"
}

function prependEtcEnvironmentPath {
    element="$1"
    prependEtcEnvironmentVariable PATH "${element}"
}

function appendEtcEnvironmentPath {
    element="$1"
    appendEtcEnvironmentVariable PATH "${element}"
}

# Process /etc/environment as if it were shell script with `export VAR=...` expressions
#    The PATH variable is handled specially in order to do not override the existing PATH
#    variable. The value of PATH variable read from /etc/environment is added to the end
#    of value of the exiting PATH variable exactly as it would happen with real PAM app read
#    /etc/environment
#
# TODO: there might be the others variables to be processed in the same way as "PATH" variable
#       ie MANPATH, INFOPATH, LD_*, etc. In the current implementation the values from /etc/evironments
#       replace the values of the current environment
function  reloadEtcEnvironment {
    # add `export ` to every variable of /etc/environemnt except PATH and eval the result shell script
    eval $(grep -v '^PATH=' /etc/environment | sed -e 's%^%export %')
    # handle PATH specially
    etc_path=$(getEtcEnvironmentVariable PATH)
    export PATH="$PATH:$etc_path"
}

#refer function pathmunge in /etc/profile
#pathmunge /your/new/path after ;export PATH 
function injectpath {
    source /etc/profile.d/sh.local
    case ":${PATH}:" in
        *:"$1":*)
            ;;
        *)
            if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
            else
                PATH=$1:$PATH
            fi
    esac
    export PATH
    sed -i -e "/\s*PATH\=.*/d" /etc/profile.d/sh.local
    echo "PATH=${PATH};export PATH" >> /etc/profile.d/sh.local
}

function injectenv {
    eval "$1"
    rv=$?
    export $1
    if [[ $rv -ne 0 ]];then
        sed -i -e "/\s*${1}\=.*/d" /etc/profile.d/sh.local
        echo "export $1" >> /etc/profile.d/sh.local
    else
        echo "syntax error, use envset syntax KEY=Val."
    fi
}

