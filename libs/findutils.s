# Collection of GNU find, xargs, and locate

# shellcheck disable=SC2034
libs_desc="Collection of GNU find, xargs, and locate"

libs_lic='GPL-3.0-or-later'
libs_ver=4.10.0
libs_url=https://ftpmirror.gnu.org/gnu/findutils/findutils-$libs_ver.tar.xz
libs_sha=1387e0b67ff247d2abde998f90dfbf70c1491391a59ddfecb8ae698789f0a4f5
libs_dep=()

libs_args=(
    # static only
    --enable-static --disable-shared

    # always disable nls for single static executable, or
    #  => PREFIX/share/locale will hardcoded into executable
    --disable-nls
    --without-libintl-prefix
    --without-libiconv-prefix
)

libs_build() {
    # disclaim rust findutils versions
    cmdlet.disclaim 0.10.0

    configure

    make

    # test only find
    make -C find check

    # pack xargs with find
    cmdlet.pkginst findutils bin \
        ./find/find ./xargs/xargs

    # seperate packing
    cmdlet.install ./find/find

    cmdlet.install ./xargs/xargs

    # verify
    check find --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
