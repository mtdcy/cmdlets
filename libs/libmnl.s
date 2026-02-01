# libmnl is a minimalistic user-space library oriented to Netlink developers.

# shellcheck disable=SC2034
libs_lic='LGPLv2.1+'
libs_ver=1.0.5
libs_url=https://www.netfilter.org/projects/libmnl/files/libmnl-1.0.5.tar.bz2
libs_sha=274b9b919ef3152bfb3da3a13c950dd60d6e2bcd54230ffeca298d03b40d0525
libs_dep=( )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-shared
    --enable-static
)

libs_build() {
    depends_on is_linux

    configure

    pkgfile libmnl -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
