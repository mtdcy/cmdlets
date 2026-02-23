# Collection of GNU find, xargs, and locate

# shellcheck disable=SC2034
libs_desc="Collection of GNU find, xargs, and locate"

libs_lic='GPL-3.0-or-later'
libs_ver=4.10.0
libs_url=https://ftpmirror.gnu.org/gnu/findutils/findutils-$libs_ver.tar.xz
libs_sha=1387e0b67ff247d2abde998f90dfbf70c1491391a59ddfecb8ae698789f0a4f5
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --localstatedir=/var/locate

    --with-included-regex
    --without-selinux
    --disable-acl

    --disable-shared
    --enable-static

    # always disable nls for single static executable, or
    #  => PREFIX/share/locale will hardcoded into executable
    --disable-nls

    --disable-debug
    --disable-doc
    --disable-man

    --with-packager=cmdlets
)

libs_build() {
    dynamically_if_glibc || true

    configure &&

    make &&

    # test only find
    make -C find check &&

    # install cmdlets and symlinks
    cmdlet find/find gfind find &&
    cmdlet xargs/xargs          &&
    cmdlet locate/locate        &&

    # verify
    check gfind --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
