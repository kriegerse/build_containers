#!/usr/bin/env bash

# get OS release info
source /etc/os-release
BASE_VERSION_ID=${VERSION_ID%.*}


env

# add MariaDB repository
zypper -vvv -n --gpg-auto-import-keys refresh
zypper -vvv -n in curl
rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
zypper -vvv -n ar --gpgcheck --refresh https://yum.mariadb.org/${MARIADB_VERSION}/opensuse/${BASE_VERSION_ID}/x86_64 mariadb
zypper -vvv -n --gpg-auto-import-keys refresh

# install software
zypper -vvv -n in ${MARIADB_PACKAGES}
zypper -vvv -n rm --clean-deps curl 
zypper -vvv -n clean --all


# self cleanup
rm -f $0
