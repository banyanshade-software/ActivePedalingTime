#!/bin/bash

# quick and dirty script for building
# because vs code extension does not show (apparently) edge explorer
#
# a full clean script (or preferably makefile) is to be done
#

SDKDIR="${HOME}/Library/Application Support/Garmin/ConnectIQ/Sdks"
SDK="${SDKDIR}/connectiq-sdk-mac-8.2.2-2025-07-17-cf29b22d5/bin/monkeybrains.jar"
SCRIPT_DIR=$( CDPATH= cd -P -- "$(dirname -- "$BASH_SOURCE")" && pwd)
PDIR="$SCRIPT_DIR"

java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
    -jar "$SDK" \
    -o "${PDIR}/build/pausedf.prg" \
    -f "${PDIR}/monkey.jungle" \
    -y "/Users/danielbraun/devel/garmin/developer_key" \
    -d edgeexplore \
    -w 
