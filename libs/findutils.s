# Collection of GNU find, xargs, and locate

# shellcheck disable=SC2034
libs_desc="Collection of GNU find, xargs, and locate"

libs_lic='GPL-3.0-or-later'
libs_ver=4.11.0
libs_rev=1
libs_url=https://ftpmirror.gnu.org/gnu/findutils/findutils-$libs_ver.tar.xz
libs_sha=bfd19cb06cc71f3352d567e90284d8cdac02ac89774bbeadf0b533b0c11432fd
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

    findutils=(find xargs)

    # install find utils
    for x in "${findutils[@]}"; do
        cmdlet.install $x/$x
    done

    # pack xargs with find
    cmdlet.pkgfile findutils $(printf "bin/%s " "${findutils[@]}")

    # verify
    cmdlet.verify -- find --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
