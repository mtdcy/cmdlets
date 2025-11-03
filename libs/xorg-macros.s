# X.Org: Set of autoconf macros used to build other xorg packages

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.20.2
libs_url=https://www.x.org/archive/individual/util/util-macros-1.20.2.tar.xz
libs_sha=9ac269eba24f672d7d7b3574e4be5f333d13f04a7712303b1821b2a51ac82e8e
libs_dep=( )

libs_args=(
    --disable-silent-rules
    --sysconfdir=/etc
    --localstatedir=/var
)

libs_build() {
    configure

    make.all

    pkgfile $libs_name -- make.install

    # test
    # xorg installed pkgconfig into share instead of lib
    export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$PREFIX/share/pkgconfig"
    slogcmd "$PKG_CONFIG" --print-errors --variable=pkgdatadir xorg-macros || die "test failed."
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
