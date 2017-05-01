FROM babim/plex
USER root

RUN apt-get update && \
    apt-get install -y fuse python3 python3-appdirs python3-dateutil python3-requests python3-sqlalchemy python3-pip git

# install acd_cli
RUN pip3 install --upgrade git+https://github.com/yadayada/acd_cli.git

# clean
RUN apt-get purge git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY root /
RUN chmod +x plex-entrypoint.sh

VOLUME ["/config", "/media"]

USER root

WORKDIR /usr/lib/plexmediaserver
