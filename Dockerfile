FROM babim/plex:alpine

USER root

COPY root /
RUN chmod +x /plex-entrypoint.sh

USER plex

WORKDIR /glibc
