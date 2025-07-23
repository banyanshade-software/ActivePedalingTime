#!/bin/sh
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar "/Users/danielbraun/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.2.2-2025-07-17-cf29b22d5/bin/monkeybrains.jar" \
    -o /Users/danielbraun/devel/garmin/pausedf/build/pausedf.prg \
    -f /Users/danielbraun/devel/garmin/pausedf/monkey.jungle \
    -y /Users/danielbraun/devel/garmin/developer_key \
    -d edgeexplore \
    -w 
