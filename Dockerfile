FROM babim/plex:alpine
USER root
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
RUN rm -f /*.sh
COPY root /
RUN chmod +x /*.sh

USER root

WORKDIR /glibc

VOLUME ["/config", "/media", "/cache", "/data", "/cloud"]
EXPOSE 32400 32469 8324 3005 1900/udp 5353/udp 32410/udp 32412/udp 32413/udp 32414/udp 8181

ENTRYPOINT ["/usr/local/bin/dumb-init", "/plex-entrypoint.sh"]
CMD ["/glibc/start_pms"]
