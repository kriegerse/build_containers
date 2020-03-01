FROM opensuse/leap:latest
ARG FS_BASE=''

# Configure security repo using leap os-release
COPY ./${FS_BASE}/config_clamav.sh /usr/local/bin/
COPY ./${FS_BASE}/start_clam.sh /usr/local/bin/

# install + configure clamav + supervisor
RUN bash /usr/local/bin/config_clamav.sh

# supervisord config
COPY ./${FS_BASE}/supervisord/supervisord.conf /etc/supervisord.conf
COPY ./${FS_BASE}/supervisord/clamav.conf /etc/supervisord.d/.

EXPOSE 3310/tcp

CMD ["/usr/bin/supervisord"]
