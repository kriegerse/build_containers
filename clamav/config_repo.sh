#!/usr/bin/env bash

set -x

cat /etc/resolv.conf

nslookup download.opensuse.org
nslookup google.de

nslookup download.opensuse.org 1.1.1.1
nslookup google.de 1.1.1.1



# get OS release info
source /etc/os-release

# add security repository and import keys
zypper -vvv ar http://download.opensuse.org/repositories/security/openSUSE_Leap_${VERSION_ID}/security.repo
zypper -vvv --gpg-auto-import-keys refresh
