FROM opensuse/leap:latest AS builder
RUN zypper -n in cargo gcc \
    && cargo install --force --bin boringtun --root /usr/local boringtun


FROM opensuse/leap:latest
ARG FS_BASE=''
COPY --from=builder /usr/local/bin/boringtun /usr/local/bin/
COPY ./${FS_BASE}/files/bin  /usr/local/bin/.

RUN zypper -vvv -n in wireguard-tools iproute2 iputils iptables bash-completion \
    && zypper -vvv -n clean --all \
    && chmod -v +x /usr/local/bin/*

ENV WG_LOG_LEVEL="info" \
    WG_QUICK_USERSPACE_IMPLEMENTATION="boringtun" \
    WG_SUDO=1 \
    WG_ERR_LOG_FILE=/dev/stderr \
    WG_LOG_FILE=/dev/stdout

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["wg0"]

HEALTHCHECK --interval=5s --timeout=3s --start-period=30s --retries=3 \
  CMD  pgrep -aw boringtun  || exit 1
