# X.Org: A Sample Authorization Protocol for X

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.0.12
libs_url=https://www.x.org/archive/individual/lib/libXau-1.0.12.tar.xz
libs_sha=74d0e4dfa3d39ad8939e99bda37f5967aba528211076828464d2777d477fc0fb
libs_dep=( xorgproto xorg-macros )

libs_args=(
    --disable-silent-rules
    --sysconfdir=/etc
    --localstatedir=/var

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make.all

    pkgfile $libs_name -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
