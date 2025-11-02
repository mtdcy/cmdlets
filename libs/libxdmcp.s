# X.Org: X Display Manager Control Protocol library

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.1.5
libs_url=https://www.x.org/archive/individual/lib/libXdmcp-1.1.5.tar.xz
libs_sha=d8a5222828c3adab70adf69a5583f1d32eb5ece04304f7f8392b6a353aa2228c
libs_dep=( xorgproto )

libs_args=(
    --disable-silent-rules
    --sysconfdir=/etc
    --localstatedir=/var

    --enable-docs=no

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make.all

    pkgfile $libs_name -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
