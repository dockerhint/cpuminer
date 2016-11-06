FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive

ENV DEBIAN_FRONTEND noninteractive

RUN groupadd -r nicehash \
  && useradd -r -g nicehash -m -d /home/nicehash/ -G sudo nicehash

ARG NHEQMINER_GIT_URL=https://github.com/tpruvot/cpuminer-multi.git
ARG NHEQMINER_BRANCH=linux

ENV GOSU_VERSION 1.10

RUN DEBIAN_FRONTEND=noninteractive; \
  apt-get autoclean && apt-get autoremove && apt-get update \
  && apt-get -qqy install --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    git \
    libboost-all-dev \
    wget autoconf automake libjansson-dev libgmp-dev \
    libcurl4-openssl-dev libssl-dev libtool libncurses5-dev \
  && rm -rf /var/lib/apt/lists/*
  # Get gosu
RUN dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true
  # Build NiceHash Equihash Miner
RUN gosu nicehash mkdir -p /tmp/build && chown nicehash:nicehash /tmp/build \
    && gosu nicehash git clone -b "$NHEQMINER_BRANCH" "$NHEQMINER_GIT_URL" /tmp/build/cpuminer-multi \
    && cd /tmp/build/cpuminer-multi \
    && gosu nicehash ./autogen.sh \
    && gosu nicehash ./configure --with-crypto --with-curl CFLAGS="-O2 -march=native -DUSE_ASM -pg" \
    && gosu nicehash make -j 4 \
#    && gosu nicehash strip -s cpuminer \

  # Install nheqminer_cpu
    && /usr/bin/install -g nicehash -o nicehash -s -c cpuminer -t /usr/local/bin/
  # Cleanup
RUN rm -rf /tmp/build/ \
    && apt-get purge -y --auto-remove

WORKDIR /home/nicehash

COPY entrypoint.sh /home/nicehash/entrypoint.sh
RUN chmod +x /home/nicehash/entrypoint.sh

# Metadata params
ARG BUILD_DATE
ARG VERSION
ARG VCS_URL
ARG VCS_REF
# Metadata
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="cpuminer" \
      org.label-schema.description="Running cpuminer in docker container" \
      org.label-schema.url="https://etherchain.org/" \
      org.label-schema.vcs-url=$VCS_URL \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vendor="AnyBucket" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0" \
      com.microscaling.docker.dockerfile="/Dockerfile"

ENTRYPOINT ["./entrypoint.sh"]
CMD ["-h"]
