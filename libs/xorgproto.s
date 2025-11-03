# X.Org: Protocol Headers

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=2024.1
libs_url=https://xorg.freedesktop.org/archive/individual/proto/xorgproto-2024.1.tar.gz
libs_sha=4f6b9b4faf91e5df8265b71843a91fc73dc895be6210c84117a996545df296ce
libs_dep=( xorg-macros )

libs_args=(
    --disable-silent-rules
    --sysconfdir=/etc
    --localstatedir=/var
)

libs_build() {
    # xorg installed pkgconfig into share instead of lib
    export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$PREFIX/share/pkgconfig"

    configure

    make.all

    pkgfile $libs_name -- make.install

    slogcmd "$PKG_CONFIG" --print-errors --cflags xproto || die "test failed"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
