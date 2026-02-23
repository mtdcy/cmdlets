# X.Org: Interface to the X Window System protocol

libs_targets=( linux darwin )

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
    --disable-devel-docs
    --without-doxygen

    PYTHON=python3

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make.all

    pkgfile $libs_name -- make.install SUBDIRS=src BUILT_MAN_PAGES=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
