ARG WP_VERSION='5.7'
ARG PHP_VERSION='php8.0'


FROM wordpress:${WP_VERSION}-${PHP_VERSION}-apache
ARG FS_BASE=''
ARG WP_VERSION

ENV WP_VERSION=${WP_VERSION}

COPY ./${FS_BASE}/files  /usr/local/.
RUN bash /usr/local/bin/prepare_container.sh
