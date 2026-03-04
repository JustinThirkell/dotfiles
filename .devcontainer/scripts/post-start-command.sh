#!/bin/bash
set -e

sudo /usr/local/bin/init-firewall.sh >/tmp/firewall-setup.log 2>&1
/workspace/.devcontainer/scripts/setup-environment.sh
