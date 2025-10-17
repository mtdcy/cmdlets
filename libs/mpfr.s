# C library for multiple-precision floating-point computations
#
# shellcheck disable=SC2034

libs_desc="C library for multiple-precision floating-point computations"
libs_page="https://www.mpfr.org/"

libs_lic='GPL-3.0-or-later'
libs_ver=4.2.2
libs_url=https://ftpmirror.gnu.org/gnu/mpfr/mpfr-$libs_ver.tar.xz
libs_sha=b67ba0383ef7e8a8563734e2e889ef5ec3c3b898a01d00fa0a6869ad81c6ce01
libs_dep=(gmp)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-gmp="'$PREFIX'"

    --disable-docs

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    is_darwin || export CXXFLAGS+=" --static-libquadmath"

    configure && make && make check || return $?

    # nobase_dist_doc_DATA: no examples
    pkgfile libmpfr -- make install nobase_dist_doc_DATA=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
