FROM opensuse/leap:latest
ARG FS_BASE=''

# Configure security repo using leap os-release
COPY ./${FS_BASE}/config_repo.sh /usr/local/bin/
RUN bash /usr/local/bin/config_repo.sh

# clamav + supervisor
RUN zypper -n in clamav supervisor
RUN zypper clean --all

# supervisord start scripts
COPY ./supervisord/supervisord.conf /etc/supervisord.conf
COPY ./supervisord/clamav.conf /etc/supervisord.d/.
COPY ./start_clam.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start_clam.sh

# change signature dir to /data/db, add /data/conf for individual user configs
RUN install -D -d -o vscan -g vscan -m 750 /data/db
RUN install -D -d -o vscan -g vscan -m 750 /data/conf
RUN sed -i -e 's|^#DatabaseDirectory|DatabaseDirectory|' /etc/clamd.conf /etc/freshclam.conf
RUN sed -i -e 's|^DatabaseDirectory.*$|DatabaseDirectory /data/db|' /etc/clamd.conf /etc/freshclam.conf


EXPOSE 3310/tcp

CMD ["/usr/bin/supervisord"]
