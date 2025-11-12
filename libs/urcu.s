# Library for userspace RCU (read-copy-update)

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=0.15.5
libs_url=https://lttng.org/files/urcu/userspace-rcu-0.15.5.tar.bz2
libs_sha=b2f787a8a83512c32599e71cdabcc5131464947b82014896bd11413b2d782de1
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
