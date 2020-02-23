#!/usr/bin/env bash

# get OS release info
source /etc/os-release

# add security repository and import keys
zypper ar http://download.opensuse.org/repositories/security/openSUSE_Leap_${VERSION_ID}/security.repo
zypper --gpg-auto-import-keys refresh
