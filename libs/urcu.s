# Library for userspace RCU (read-copy-update)

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=0.15.3
libs_url=https://lttng.org/files/urcu/userspace-rcu-0.15.3.tar.bz2
libs_sha=26687ec84e3e114759454c884a08abeaf79dec09b041895ddf4c45ec150acb6d
libs_dep=( )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-debug

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    pkgfile liburcu -- make install SUBDIRS="'include src'"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
