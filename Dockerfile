FROM babim/plex:alpine

# create dirs for the config, local mount point, and cloud destination
#RUN mkdir /config /cache /data /cloud
RUN mkdir /cache /data /cloud

# set the cache, settings, and libfuse path accordingly
ENV ACD_CLI_CACHE_PATH /cache
ENV ACD_CLI_SETTINGS_PATH /cache
ENV LIBFUSE_PATH /usr/lib/libfuse.so.2

# install python 3, fuse, and git
RUN apk add --no-cache python3 fuse git && pip3 install --upgrade pip

# install acd_cli
RUN pip3 install --upgrade git+https://github.com/yadayada/acd_cli.git

# no need for git or the apk cache anymore
RUN apk del git

# install openvpn and supervisor
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    echo "http://dl-4.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --no-cache rsyslog supervisor openvpn

COPY root /
RUN chmod +x /plex-entrypoint.sh && chmod +x /acdcli-entrypoint.sh && chmod +x /entrypoint.sh

USER plex

WORKDIR /glibc

VOLUME ["/config", "/media", "/cache", "/data", "/cloud", "/etc/openvpn"]
EXPOSE 32400 32469 8324 3005 1900/udp 5353/udp 32410/udp 32412/udp 32413/udp 32414/udp 8181

ENV CLIENT_CONFIG_FILE /etc/openvpn/client.conf

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENTRYPOINT ["/entrypoint.sh"]
CMD ["app:start"]
