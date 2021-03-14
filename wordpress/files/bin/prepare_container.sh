#!/usr/bin/env bash

# exit on any error
set -ex

# DEFINE VARS
OS_PACKAGES="less cron libzstd1 libtidy5deb1 libsnmp30 unzip libmagickcore-6.q16-6-extra"
OS_PACKAGES_TEMP="libbz2-dev libldap2-dev libzstd-dev libicu-dev libsnmp-dev libtidy-dev"
# ToDo add libmagickcore-dev libmagickwand-dev as soon as compatible with php8
PHP_MODULES="opcache bz2 ldap intl calendar pcntl snmp sysvmsg sysvsem sysvshm tidy"
WP_PLUGINS="add-search-to-menu antispam-bee authldap complianz-gdpr redis-cache safe-redirect-manager statify wp-code-highlightjs"
WP_THEMES="twentyseventeen"
WP_LANGUAGES="de_DE"

export GNUMAKEFLAGS="-j$(nproc) "



### install additional libraries + tools ###
apt-get update
apt-get install -y --no-install-recommends ${OS_PACKAGES}

### install additional dev libs for php modules ###
apt-get install -y --no-install-recommends ${OS_PACKAGES_TEMP}

### use producation php.ini
ln -s "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

### install PHP_MODULES
for PHP_MODULE in ${PHP_MODULES}; do
  echo "Processing PHP Module: ${PHP_MODULE}"
  docker-php-ext-configure ${PHP_MODULE}
  docker-php-ext-install -j$(nproc) ${PHP_MODULE}
  docker-php-ext-enable ${PHP_MODULE}
done
# fix double entry for opcache
sed -i -e '/^zend_extension=opcache$/ d' /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini


### install PHP_PECL_MODULES
# apcu
echo "Processing PHP Module: apcu"
pecl install apcu
docker-php-ext-enable apcu
# igbinary
echo "Processing PHP Module: igbinary"
pecl install igbinary
docker-php-ext-enable igbinary
# lzf
echo "Processing PHP Module: lzf"
pecl install --configureoptions 'enable-lzf-better-compression="no"' lzf
docker-php-ext-enable lzf
# redis
echo "Processing PHP Module: redis"
pecl install --configureoptions 'enable-redis-igbinary="yes" enable-redis-lzf="yes" enable-redis-zstd="yes"' redis
docker-php-ext-enable redis
# imagick ToDo as soon as compatible with php8.0
# pecl install imagick


### wordpress plugins
pushd /usr/src/wordpress/wp-content/plugins
for WP_PLUGIN in ${WP_PLUGINS}; do
  echo "Processing Plugin: ${WP_PLUGIN}"
  curl -o "${WP_PLUGIN}.zip" "https://downloads.wordpress.org/plugin/${WP_PLUGIN}.zip"
  unzip "${WP_PLUGIN}.zip"
  rm "${WP_PLUGIN}.zip"
  chown -R www-data:www-data "${WP_PLUGIN}"
done
# place redis object-cache.php drop-in (ToDO)
ln -s plugins/redis-cache/includes/object-cache.php ../object-cache.php
popd

### wordpress themes
pushd /usr/src/wordpress/wp-content/themes
for WP_THEME in ${WP_THEMES}; do
  echo "Processing Theme: ${WP_THEME}"
  curl -o "${WP_THEME}.zip" "https://downloads.wordpress.org/theme/${WP_THEME}.zip"
  unzip "${WP_THEME}.zip"
  rm "${WP_THEME}.zip"
  chown -R www-data:www-data "${WP_THEME}"
done
popd

### wordpress translations
if [ ! -d /usr/src/wordpress/wp-content/languages ]; then
  install -d -o www-data -g www-data /usr/src/wordpress/wp-content/languages
fi
pushd /usr/src/wordpress/wp-content/languages
for WP_LANGUAGE in ${WP_LANGUAGES}; do
  echo "Processing Language Pack: ${WP_LANGUAGE}"
  curl -o "${WP_LANGUAGE}.zip" "https://downloads.wordpress.org/translation/core/${WP_VERSION}/${WP_LANGUAGE}.zip"
  unzip "${WP_LANGUAGE}.zip"
  rm "${WP_LANGUAGE}.zip"
done
chown -R www-data:www-data .
popd


### wordpress cron (insert cronjob in entrypoint)
sed -i -e '/^exec/i exec /usr/local/bin/docker-cron.sh &' /usr/local/bin/docker-entrypoint.sh
chmod u+x /usr/local/bin/docker-cron.sh
chown root:root /usr/local/etc/wordpress_cron
chmod 640 /usr/local/etc/wordpress_cron
ln -s /usr/local/etc/wordpress_cron /etc/cron.d/wordpress_cron



### CLEANUP
pecl clear-cache
apt-get purge -y ${OS_PACKAGES_TEMP}
apt-get autoremove -y
apt-get clean -y
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/pear
rm -f $0
