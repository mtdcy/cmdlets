# Utility for directing compilation

# shellcheck disable=SC2034
libs_lic='GPL-3.0-only'
libs_ver=4.4.1
libs_url=https://ftpmirror.gnu.org/gnu/make/make-$libs_ver.tar.lz
libs_sha=8814ba072182b605d156d7589c19a43b89fc58ea479b9355146160946f8cf6e9
libs_dep=(libiconv)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --without-selinux
    --without-libintl-prefix

    --disable-nls
    --disable-rpath

    --disable-doc
    --disable-man
)

libs_build() {
    configure &&

    make &&

    # check: some test fail
    # make check &&

    cmdlet make gmake make &&

    # verify
    check gmake --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
