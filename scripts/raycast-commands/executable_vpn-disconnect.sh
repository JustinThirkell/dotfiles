#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title VPN disconnect
# @raycast.mode fullOutput
# @raycast.packageName VPN
# @raycast.icon images/ciscoanyconnectsecureclient.png

echo -n "Disconnecting vpn connection..."
/opt/cisco/secureclient/bin/vpn disconnect &> /dev/null
echo "Done"
