FROM babim/alpinebase:edge
ENV OPENVPN_OPTION true

## alpine linux
RUN apk add --no-cache wget bash && cd / && wget --no-check-certificate https://raw.githubusercontent.com/babim/docker-tag-options/master/z%20SCRIPT%20AUTO/option.sh && \
    chmod 755 /option.sh

# install
RUN wget --no-check-certificate -O - https://raw.githubusercontent.com/babim/docker-tag-options/master/z%20Plexmedia%20install/plex_install.sh | bash

USER plex

WORKDIR /glibc

VOLUME ["/config", "/media", "/cache", "/data", "/cloud", "/etc/openvpn"]
EXPOSE 32400 32469 8324 3005 1900/udp 5353/udp 32410/udp 32412/udp 32413/udp 32414/udp 8181

ENV CLIENT_CONFIG_FILE /etc/openvpn/client.conf

ENTRYPOINT ["/openvpn-entrypoint.sh"]
CMD ["app:start"]

