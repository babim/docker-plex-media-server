FROM babim/plex:alpine
USER root
# install openvpn and supervisor
RUN echo "http://dl-4.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    echo "http://dl-4.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk add --no-cache rsyslog supervisor openvpn

COPY root /
RUN chmod +x /plex-entrypoint.sh && chmod +x /entrypoint.sh

USER plex

WORKDIR /glibc

VOLUME ["/config", "/media", "/cache", "/data", "/cloud", "/etc/openvpn"]
EXPOSE 32400 32469 8324 3005 1900/udp 5353/udp 32410/udp 32412/udp 32413/udp 32414/udp 8181

ENV CLIENT_CONFIG_FILE /etc/openvpn/client.conf

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ENTRYPOINT ["/entrypoint.sh"]
CMD ["app:start"]
