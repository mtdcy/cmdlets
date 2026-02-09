# Library for userspace RCU (read-copy-update)

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=0.15.6
libs_url=https://lttng.org/files/urcu/userspace-rcu-0.15.6.tar.bz2
libs_sha=850b192096eb11ebf2c70e8f97bc7da7479ee41da1bebeb44e3986908bac414f
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

libs.depends ! is_mingw

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
