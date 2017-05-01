FROM babim/plex:alpine

COPY root /
RUN chmod +x /plex-entrypoint.sh

USER root

WORKDIR /glibc
