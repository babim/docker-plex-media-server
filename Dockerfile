FROM babim/alpinebase:edge

## alpine linux
RUN apk add --no-cache wget bash && cd / && wget --no-check-certificate https://raw.githubusercontent.com/babim/docker-tag-options/master/z%20SCRIPT%20AUTO/option.sh && \
    chmod 755 /option.sh && apk del wget



USER plex

WORKDIR /glibc

VOLUME ["/config", "/media"]
EXPOSE 32400 32469 8324 3005 1900/udp 5353/udp 32410/udp 32412/udp 32413/udp 32414/udp 8181

ENTRYPOINT ["/plex-entrypoint.sh"]
CMD ["/glibc/start_pms"]
