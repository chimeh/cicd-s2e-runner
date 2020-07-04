#!/bin/bash
################################################################################
##  File:  document.sh
##  Desc:  Helper functions for writing information to the metadata document
################################################################################

DOC_FILE=${DOC_FILE:-/.buildnote.md}
function WriteItem {
    if [ -z "$DOC_FILE" ]; then
        echo "DOC_FILE environment variable must be set to output to Metadata Document!"
        return 1;
    else
        echo -e "$1" | sudo tee -a "$DOC_FILE"
    fi
}

function AddTitle {
	WriteItem "# $(echo $1 |head -n)"
}

function AddSubTitle {
	WriteItem "## $(echo $1 | head -n 1)"
}

function DocumentInstalledItem {
	WriteItem "- $(echo $1 |head -n 1)"
}

function DocumentInstalledItemIndent {
	WriteItem "  - $(echo $1 | head -n 1)"
}
