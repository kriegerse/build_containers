# ClamAV - openSUSE_Leap based

RUN sed -i -e 's|^#DatabaseDirectory|DatabaseDirectory|' /etc/clamd.conf /etc/freshclam.conf
RUN sed -i -e 's|^DatabaseDirectory.*$|DatabaseDirectory /data/db|' /etc/clamd.conf /etc/freshclam.conf

CMD ["/usr/bin/supervisord"]
