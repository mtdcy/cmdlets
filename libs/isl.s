# Integer Set Library for the polyhedral model
#
# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.27
libs_url=https://libisl.sourceforge.io/isl-0.27.tar.xz
libs_sha=6d8babb59e7b672e8cb7870e874f3f7b813b6e00e6af3f8b04f7579965643d5c

libs_deps=( gmp )

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-gmp=system
    --with-gmp-prefix="'$PREFIX'"

    --disable-docs

    # static only
    --disable-shared
    --enable-static
)

libs_build() {

    configure

    make

    #make check

    # nobase_dist_doc_DATA: no examples
    pkgfile libisl -- make install nobase_dist_doc_DATA=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
