# 
# Common dependencies for OT.one
#

# for ARM use this
FROM vimagick/alpine-arm:3.3
# for x86 use this
# FROM gliderlabs/alpine:3.3

# for ARM uncomment this and run this on the host machine:
# mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc  
# echo ':arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-arm-static:' > /proc/sys/fs/binfmt_misc/register  
#COPY qemu-arm-static /usr/bin/qemu-arm-static

RUN apk update && \
    apk add \
    ca-certificates \
    python3 \
    wget

RUN apk del wget ca-certificates && rm -rf /var/cache/apk/*

RUN apk update && apk add \
    build-base \ 
    ca-certificates \
    libffi-dev \ 
    python3 \
    python3-dev \
    wget \ 
    && wget "https://bootstrap.pypa.io/get-pip.py" -O /dev/stdout | python3

WORKDIR /home

RUN apk update \
    && apk add build-base \
    libbz2 \
    libffi \
    libffi-dev \
    libsodium-dev \
    linux-headers \
    ncurses-libs \
    openssl-dev \
    readline \
    sqlite-libs

# patch setproctitle, build and install it
# Install crossbar
# We are installing libsodium from alpine package repsitory so we don't have
# to compile it locally
COPY patch.diff py-setproctitle-version-1.1.9/src/patch.diff
RUN wget https://github.com/dvarrazzo/py-setproctitle/archive/version-1.1.9.zip -O temp.zip && unzip temp.zip \
    && cd py-setproctitle-version-1.1.9/src/ && patch spt_status.c < patch.diff && cd ../.. \
    && cd py-setproctitle-version-1.1.9/ && python3 setup.py install bdist && cd .. \
    && rm temp.zip \
    && rm -rf py-setproctitle-version-1.1.9 \
    && SODIUM_INSTALL=system pip install autobahn==0.12.1 crossbar[all]==0.12.1 \
    && mkdir /home/.crossbar && wget https://raw.githubusercontent.com/OpenTrons/otone_backend/master/.crossbar/config.yaml -O /home/.crossbar/config.yaml

#ENTRYPOINT ["tar", "-cvz", "/usr/lib/python3.5/site-packages/", "/usr/bin/crossbar", "/home/.crossbar"]

# You need to forward port 8080 with "-p 8080" on the command-line:
# docker run -p 8080 crossbar
ENTRYPOINT ["crossbar", "start", "--cbdir", ".crossbar"]
