#!/bin/bash
THIS_SCRIPT=$(realpath $(cd "$(dirname "${BASH_SOURCE:-$0}")"; pwd)/$(basename ${BASH_SOURCE:-$0}))
#automatic detection TOPDIR
SCRIPT_DIR=$(dirname $(realpath ${THIS_SCRIPT}))

S2EPATH_FILE="/etc/profile.d/s2e.sh"

#refer function pathmunge in /etc/profile
#pathmunge /your/new/path after ;export PATH 
function injectpath {
    echo "pathmunge $1" >> ${S2EPATH_FILE}
    . /etc/profile
}

function injectenv {
   . ${S2EPATH_FILE}
    eval "$1"
    rv=$?
    export $1
    if [[ $rv -ne 0 ]];then
        sed -i -e "export ${1}\=.*/d ## auto inject" ${S2EPATH_FILE}
        echo "export $1 ## auto inject" >> ${S2EPATH_FILE}
    else
        echo "syntax error, use envset syntax KEY=Val."
    fi
}

