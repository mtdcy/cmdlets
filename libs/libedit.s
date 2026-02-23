# BSD-style licensed readline alternative

libs_targets=( linux darwin )

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=3.1
libs_url=https://thrysoee.dk/editline/libedit-20251016-3.1.tar.gz
libs_sha=21362b00653bbfc1c71f71a7578da66b5b5203559d43134d2dd7719e313ce041
libs_dep=( ncurses )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-shared
    --enable-static
)

is_linux && libs_args+=( --with-privsep-path=/var/lib/sshd )

libs_build() {
    # libedit do not use pkg-config
    libs.requires ncurses

    configure

    make

    pkgfile libedit -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
