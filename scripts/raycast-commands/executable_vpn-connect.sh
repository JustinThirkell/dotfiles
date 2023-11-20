#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title VPN connect
# @raycast.mode fullOutput
# @raycast.packageName VPN
# @raycast.icon images/ciscoanyconnectsecureclient.png

# Optional parameters:
# @raycast.argument2 { "type": "text", "placeholder": "yubikey or 'push'", "secure": true}

mfa="$1"
endpoint="APSE2 Sydney (managed)"  

if [ "$mfa" = "push" ]; then
  mfamethod="push"
else
  mfamethod="yubikey"
fi

username=$(whoami)

echo "Connecting VPN..."
echo
echo -n "Reading password from 1Password..."
pass=$(op read op://Private/Atlassian/Password)
echo
echo -n "Connecting ${username} to vpn endpoint ${endpoint} using ${mfamethod}..."
echo
printf "${username}\n${pass}\n${mfa}\n" | /opt/cisco/secureclient/bin/vpn connect "$endpoint" #&> /dev/null
unset username pass mfa
echo "Done"
exit 0
