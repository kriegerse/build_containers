#!/usr/bin/env bash

set -x

# get OS release info
source /etc/os-release

# add security repository and import keys
zypper -vvv ar http://download.opensuse.org/repositories/security/openSUSE_Leap_${VERSION_ID}/security.repo
zypper -vvv --gpg-auto-import-keys refresh
