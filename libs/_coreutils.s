# GNU File, Shell, and Text utilities

# shellcheck disable=SC2034
libs_lic="GPL-3.0-or-later"
libs_ver=9.8
libs_url=https://ftpmirror.gnu.org/gnu/coreutils/coreutils-$libs_ver.tar.xz
libs_sha=e6d4fd2d852c9141a1c2a18a13d146a0cd7e45195f72293a4e4c044ec6ccca15
libs_dep=(gmp libiconv)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --without-selinux

    --disable-nls
    --disable-rpath

    --enable-no-install-program=groups,hostname,su,kill,uptime
    --enable-install-program=ln
    --enable-single-binary=symlinks

    # install common used, gnu version of bsd|busybox utils.

    --disable-doc
    --disable-man
)

[[ "${libs_dep[*]}" =~ gmp ]]       || libs_args+=(--without-gmp) # make utils more generic
[[ "${libs_dep[*]}" =~ libiconv ]]  || libs_args+=(--without-libiconv-prefix)

libs_build() {
    #dynamically_if_glibc || true

    configure &&

    make V=1 &&

    # check => there are some FAILs, help-version.sh|uid|zero
    # make check &&

    make install-exec &&

    # virsual verify
    check yes --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
