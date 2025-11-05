# Library for userspace RCU (read-copy-update)

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=0.15.4
libs_url=https://lttng.org/files/urcu/userspace-rcu-0.15.4.tar.bz2
libs_sha=11a14a7660ac9ba9c0bbd3b2d81718523d27dc6c8a9dfabd5e401b406673ee3a
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
