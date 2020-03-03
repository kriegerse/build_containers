FROM opensuse/leap:latest
ARG FS_BASE=''

# Configure security repo using leap os-release
COPY ./${FS_BASE}/files  /usr/local/.

# install + configure clamav + supervisor
RUN bash /usr/local/bin/config_clam.sh

EXPOSE 3310/tcp

CMD ["/usr/bin/supervisord"]
