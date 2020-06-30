#!/bin/bash

# Source the helpers for use with the script
source $HELPER_SCRIPTS/document.sh

# Install ImageMagick
yum install -y ImageMagick  ImageMagick-devel

# Document what was added to the image
echo "Lastly, documenting what we added to the metadata file"
DocumentInstalledItem "ImageMagick"
