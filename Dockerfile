
FROM    ubuntu:22.04
LABEL   maintainer="mtdcy.chen@gmail.com"

# ENV & ARG variables
ARG MIRROR=""
ARG TZ=Asia/Shanghai
ARG LANG=en_US.UTF-8

ENV TZ=${TZ}
ENV LANG=${LANG}
ENV LC_ALL=${LANG}
ENV LANGUAGE=${LANG}
ENV DEBIAN_FRONTEND=noninteractive

# distcc
ENV DISTCC_VERBOSE=0
ENV DISTCC_DIR=/distcc
ENV DISTCC_OPTS=
ENV DISTCC_HOSTS=

# prepare #1
RUN test ! -z "${MIRROR}" &&                          \
    sed -e "s|http://archive.ubuntu.com|${MIRROR}|g"  \
        -e "s|http://security.ubuntu.com|${MIRROR}|g" \
        -i /etc/apt/sources.list;                     \
    apt-get update &&                                 \
    apt-get install -y locales tzdata &&              \
    sed -i "/C.UTF-8/s/^# //g" /etc/locale.gen &&     \
    sed -i "/$LANG/s/^# //g" /etc/locale.gen &&       \
    locale-gen &&                                     \
    ln -svf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo "$TZ" > /etc/timezone

# prepare #2
RUN apt-get install -y                                \
        wget curl git                                 \
        xz-utils lzip unzip                           \
        build-essential                               \
        autoconf libtool pkg-config cmake meson       \
        nasm yasm bison flex                          \
        luajit perl libhttp-daemon-perl

# prepare #3
RUN apt-get install -y ccache distcc                  \
    && update-distcc-symlinks                         \
    && mkdir ${DISTCC_DIR} && chmod 777 ${DISTCC_DIR}

# clear
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# volumes
VOLUME ${DISTCC_DIR}

# use bash as default shell
RUN ln -sfv /bin/bash /bin/sh
