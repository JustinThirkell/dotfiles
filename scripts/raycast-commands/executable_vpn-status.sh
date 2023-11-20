#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title VPN status
# @raycast.mode fullOutput
# @raycast.packageName VPN
# @raycast.icon images/ciscoanyconnectsecureclient.png

/opt/cisco/secureclient/bin/vpn state | grep 'state' | uniq
