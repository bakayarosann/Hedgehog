FROM ubuntu:xenial

MAINTAINER Magica Lin <readme.md@gmail.com>

# OpenResty

ARG RESTY_VERSION="1.9.7.4"
ARG RESTY_OPENSSL_VERSION="1.0.2e"
ARG RESTY_PCRE_VERSION="8.38"
ARG RESTY_J="1"
ARG RESTY_CONFIG_OPTIONS="--prefix=/opt/openresty --with-ipv6 --with-pcre-jit"

ARG _RESTY_CONFIG_DEPS="--with-openssl=/tmp/openssl-${RESTY_OPENSSL_VERSION} --with-pcre=/tmp/pcre-${RESTY_PCRE_VERSION}"

RUN \
    DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        libncurses5-dev \
        libreadline-dev \
        make \
        perl \
        zlib1g-dev \
        postgresql \
        redis-server \
    && cd /tmp \
    && curl -fSL https://www.openssl.org/source/openssl-${RESTY_OPENSSL_VERSION}.tar.gz -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
    && curl -fSL https://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz \
    && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz \
    && tar xzf openresty-${RESTY_VERSION}.tar.gz \
    && cd /tmp/openresty-${RESTY_VERSION} \
    && ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} \
    && make -j${RESTY_J} \
    && make -j${RESTY_J} install \
    && cd /tmp \
    && rm -rf \
        openssl-${RESTY_OPENSSL_VERSION} \
        openssl-${RESTY_OPENSSL_VERSION}.tar.gz \
        openresty-${RESTY_VERSION}.tar.gz openresty-${RESTY_VERSION} \
        pcre-${RESTY_PCRE_VERSION}.tar.gz pcre-${RESTY_PCRE_VERSION} \
    && DEBIAN_FRONTEND=noninteractive apt-get remove -y --purge \
        ca-certificates \
        curl \
    && DEBIAN_FRONTEND=noninteractive apt-get autoremove -y

# Copy project files

RUN mkdir /srv/hedgehog
COPY ./src/public ./src/deps ./src/server ./src/hedgehog.sql ./src/hedgehog.lua /srv/hedgehog/
# ngx conf
COPY ./src/hedgehog.conf /opt/openresty/nginx/conf/nginx.conf
# postgres conf
RUN \
  sed -ri 's/#(synchronous_commit) .*$/\1 = off/' /etc/postgresql/9.5/main/postgresql.conf \
  && sed -ri 's/local   all             postgres .*/local all postgres trust/' /etc/postgresql/9.5/main/pg_hba.conf \
  && createdb hedgehog \
  && cat /srv/hedgehog/hedgehog.sql | psql hedgehog

VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]
