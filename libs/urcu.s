# Library for userspace RCU (read-copy-update)

libs_targets=(linux darwin)

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=0.15.7
libs_rev=1
libs_url=https://lttng.org/files/urcu/userspace-rcu-0.15.7.tar.bz2
libs_sha=2556b83adc0f9b3ac8024e613e17d014d04c4c49110604ce55fcb14eae32edd3
libs_dep=()

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-debug

    --disable-shared
    --enable-static
)

libs_build() {
    export CFLAGS+=" -D__CYGWIN__"

    bootstrap

    configure

    make

    cmdlet.pkgfile liburcu -- make install SUBDIRS="'include src'"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
