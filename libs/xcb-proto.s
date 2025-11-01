# X.Org: XML-XCB protocol descriptions for libxcb code generation

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.17.0
libs_url=https://xorg.freedesktop.org/archive/individual/proto/xcb-proto-1.17.0.tar.xz
libs_sha=2c1bacd2110f4799f74de6ebb714b94cf6f80fb112316b1219480fd22562148c
libs_dep=( )

libs_args=(
    --disable-silent-rules
    --sysconfdir=/etc
    --localstatedir=/var

    PYTHON=python3

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make.all

    pkgfile $libs_name -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
