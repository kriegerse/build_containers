FROM opensuse/leap:latest AS builder
RUN zypper -n in cargo gcc \
    && cargo install --force --bin boringtun --root /usr/local boringtun


FROM opensuse/leap:latest
COPY --from=builder /usr/local/bin/boringtun /usr/local/bin/
RUN zypper -vvv -n ar --gpgcheck --refresh -f obs://network:vpn:wireguard wireguard \
    && zypper -vvv -n --gpg-auto-import-keys refresh \
    && zypper -vvv -n in wireguard-tools iproute2 iputils iptables \
    && zypper -vvv -n clean --all


ENV WG_LOG_LEVEL=info \
    WG_QUICK_USERSPACE_IMPLEMENTATION=boringtun \
    WG_SUDO=1

CMD ["wg-quick", "up", "$1"]
