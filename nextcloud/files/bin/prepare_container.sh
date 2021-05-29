#!/usr/bin/env bash

# exit on any error
set -ex

# DEFINE VARS
OS_PACKAGES="less ffmpeg libmagickcore-6.q16-6-extra libsmbclient"
OS_PACKAGES_TEMP="libbz2-dev libc-client-dev libkrb5-dev libsmbclient-dev"
NC_APPS="apporder bookmarks calendar contacts deck files_accesscontrol
files_antivirus files_automatedtagging files_downloadactivity files_markdown
files_mindmap keeweb metadata news notes previewgenerator
tasks twofactor_totp files_retention richdocuments"

### install additional libraries + tools ###
apt-get update
apt-get install -y --no-install-recommends \
   ${OS_PACKAGES}

### install additional php modules ###
apt-get install -y --no-install-recommends \
   ${OS_PACKAGES_TEMP}

# php-imap
docker-php-ext-configure imap --with-kerberos --with-imap-ssl
docker-php-ext-install imap
docker-php-ext-enable imap
# php-bz2
docker-php-ext-install bz2
docker-php-ext-enable bz2
# smbclient (use pecl)
pecl install smbclient
docker-php-ext-enable smbclient


apt-get purge -y \
   ${OS_PACKAGES_TEMP}


### install nextcloud apps ###
# make apps not stored in apps_custom
cd /usr/src/nextcloud/config
mv apps.config.php apps.config.php_orig
# create temporary nextcloud installation
cd /usr/src/nextcloud
php occ maintenance:install \
   --admin-pass=verysecure \
   --data-dir=/tmp/nc_data
# install NC apps
for APP in ${NC_APPS} ; do
  php occ app:install --keep-disabled -vvv ${APP}
done


# notify_push requires special treating (https://github.com/nextcloud/notify_push/issues/54)
php occ app:install --keep-disabled -vvv notify_push || true

# maps unavailable due to
# https://github.com/nextcloud/maps/issues/541
# root@7413d5fbe17a:/usr/src/nextcloud# php occ app:install -vvv  --keep-disabled maps
# Error: The "unique" column option is not supported.
php occ app:install --keep-disabled -vvv maps || true

# restore saved config and cleanup
cd /usr/src/nextcloud/config
mv apps.config.php_orig apps.config.php
rm config.php
rm -rf /tmp/nc_data /usr/src/nextcloud/data/*
find /usr/src/nextcloud/apps/notify_push/bin/* -not -path "*$(arch)*" -delete || true 


# precopy to /var/www/html 
if [ "$(id -u)" = 0 ]; then
  rsync_options="-rlDog --chown www-data:root"
else
  rsync_options="-rlD"
fi
rsync $rsync_options --delete --exclude-from=/upgrade.exclude /usr/src/nextcloud/ /var/www/html/


### self cleanup ###
apt-get clean -y
rm -rf /var/lib/apt/lists/*
rm -f $0
