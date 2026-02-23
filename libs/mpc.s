# C library for the arithmetic of high precision complex numbers
#
# shellcheck disable=SC2034
libs_lic=LGPLv3+
libs_ver=1.3.1
libs_url=https://ftpmirror.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz
libs_sha=ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8

libs_deps=( gmp mpfr )

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-gmp="'$PREFIX'"
    --with-mpfr="'$PREFIX'"

    --disable-docs

    # static only
    --disable-shared
    --enable-static
)

libs_build() {

    configure

    make

    make check

    # nobase_dist_doc_DATA: no examples
    pkgfile libmpc -- make install nobase_dist_doc_DATA=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
