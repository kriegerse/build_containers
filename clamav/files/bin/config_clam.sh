#!/usr/bin/env bash

# get OS release info
source /etc/os-release

# add security repository and import keys
zypper -vvv -n ar http://download.opensuse.org/repositories/security/openSUSE_Leap_${VERSION_ID}/security.repo
zypper -vvv -n --gpg-auto-import-keys refresh

# install clamav and supervisord
zypper -vvv -n in clamav supervisor
zypper -vvv -n clean --all

# configure clamav
chmod +x /usr/local/bin/start_clam.sh
install -D -d -o vscan -g vscan -m 750 /data/db
install -D -d -o vscan -g vscan -m 750 /data/conf
sed -i -e 's|^#DatabaseDirectory|DatabaseDirectory|' /etc/clamd.conf /etc/freshclam.conf
sed -i -e 's|^DatabaseDirectory.*$|DatabaseDirectory /data/db|' /etc/clamd.conf /etc/freshclam.conf

# configure supervisord
ln -sf /usr/local/etc/supervisord.conf /etc/supervisord.conf
ln -sf /usr/local/etc/supervisord.d/clamav.conf /etc/supervisord.d/clamav.conf
