# X.Org: Interface to the X Window System protocol

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.17.0
libs_url=https://xorg.freedesktop.org/archive/individual/lib/libxcb-1.17.0.tar.xz
libs_sha=599ebf9996710fea71622e6e184f3a8ad5b43d0e5fa8c4e407123c88a59a6d55
libs_dep=( libxau libxdmcp xcb-proto )

libs_args=(
    --disable-silent-rules
    --sysconfdir=/etc
    --localstatedir=/var

    --enable-dri3
    --enable-ge
    --enable-xevie
    --enable-xprint
    --enable-selinux
    --disable-silent-rules
    --enable-devel-docs=no
    --with-doxygen=no

    PYTHON=python3

    --disable-shared
    --enable-static
)

libs_build() {
    # xorg installed pkgconfig into share instead of lib
    export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$PREFIX/share/pkgconfig"

    configure

    make.all

    pkgfile $libs_name -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
