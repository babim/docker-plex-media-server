FROM babim/alpinebase:edge

# Here we install GNU libc (aka glibc) and set C.UTF-8 locale as default.

ENV DESTDIR="/glibc"
ENV GLIBC_LIBRARY_PATH="$DESTDIR/lib" DEBS="libc6 libgcc1 libstdc++6"
ENV GLIBC_LD_LINUX_SO="$GLIBC_LIBRARY_PATH/ld-linux-x86-64.so.2"

WORKDIR /tmp

RUN apk add --no-cache xz binutils patchelf \

 && wget http://ftp.debian.org/debian/pool/main/g/glibc/libc6_2.24-8_amd64.deb \
 && wget http://ftp.debian.org/debian/pool/main/g/gcc-4.9/libgcc1_4.9.2-10_amd64.deb \
 && wget http://ftp.debian.org/debian/pool/main/g/gcc-4.9/libstdc++6_4.9.2-10_amd64.deb \

 && for pkg in $DEBS; do \
        mkdir $pkg; \
        cd $pkg; \
        ar x ../$pkg*.deb; \
        tar -xf data.tar.*; \
        cd ..; \
    done \

 && mkdir -p $GLIBC_LIBRARY_PATH \

 && mv libc6/lib/x86_64-linux-gnu/* $GLIBC_LIBRARY_PATH \
 && mv libgcc1/lib/x86_64-linux-gnu/* $GLIBC_LIBRARY_PATH \
 && mv libstdc++6/usr/lib/x86_64-linux-gnu/* $GLIBC_LIBRARY_PATH \
 && apk del --no-cache xz \
 && rm -rf /tmp/*

# install Plex
ENV UID=797 UNAME=plex GID=797 GNAME=plex
ADD start_pms.patch /tmp/start_pms.patch

RUN addgroup -g $GID $GNAME \
 && adduser -SH -u $UID -G $GNAME -s /usr/sbin/nologin $UNAME \
 && apk add --no-cache xz openssl file \
 && wget -O plexmediaserver.deb 'https://plex.tv/downloads/latest/1?channel=8&build=linux-ubuntu-x86_64&distro=ubuntu' \
 && ar x plexmediaserver.deb \
 && tar -xf data.tar.* \
 && find usr/lib/plexmediaserver -type f -perm /0111 -exec sh -c "file --brief \"{}\" | grep -q "ELF" && patchelf --set-interpreter \"/usr/glibc-compat/lib\" \"{}\" " \; \
 && mv /tmp/start_pms.patch usr/sbin/ \
 && cd usr/sbin/ \
 && patch < start_pms.patch \
 && cd /tmp \
 && sed -i "s|<destdir>|$DESTDIR|" usr/sbin/start_pms \

 && mv usr/sbin/start_pms $DESTDIR/ \
 && mv usr/lib/plexmediaserver $DESTDIR/plex-media-server \

 && wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 \
 && chmod +x /usr/local/bin/dumb-init \

 && apk del --no-cache xz binutils patchelf file wget \
 && rm -rf /tmp/* \
 && mkdir /config \
 && chown plex:plex /config

COPY root /
RUN chmod +x /plex-entrypoint.sh

USER plex

WORKDIR /glibc

VOLUME ["/config", "/media"]
EXPOSE 32400 32469 8324 3005 1900/udp 5353/udp 32410/udp 32412/udp 32413/udp 32414/udp 8181

ENTRYPOINT ["/usr/local/bin/dumb-init", "/plex-entrypoint.sh"]
CMD ["/glibc/start_pms"]
