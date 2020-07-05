FROM opensuse/leap:latest

ARG FS_BASE=''

ENV SQUID_CACHE_DIR=/var/cache/squid \
    SQUID_CACHE_ENGINE=aufs \
    SQUID_CACHE_SIZE=1000 \
    SQUID_CACHE_MEM=100 \
    SQUID_CONF=/etc/squid/squid.conf \
    SQUID_MAX_OBJECT_SIZE=512

COPY ./${FS_BASE}/files  /usr/local/.
RUN zypper -vvv -n refresh \
    && zypper -vvv -n in squid \
    && zypper -vvv -n clean --all \
    && chmod 755 /usr/local/bin/entrypoint.sh

EXPOSE 3128/tcp
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

HEALTHCHECK --interval=5s --timeout=3s --start-period=30s --retries=3 \
  CMD  pgrep -aw squid  || exit 1
