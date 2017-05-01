FROM babim/plex:alpine

USER root

WORKDIR /glibc

VOLUME ["/config", "/media"]
EXPOSE 32400 32469 8324 3005 1900/udp 5353/udp 32410/udp 32412/udp 32413/udp 32414/udp 8181

ENTRYPOINT ["/usr/local/bin/dumb-init", "/plex-entrypoint.sh"]
CMD ["/glibc/start_pms"]
