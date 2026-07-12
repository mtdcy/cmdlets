# Integer Set Library for the polyhedral model
#
# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.28
libs_url=https://libisl.sourceforge.io/isl-0.28.tar.xz
libs_sha=3dc31b8e1b18329e42d5dfbf84dd55e15c59b61569a2ab246f61497d9592f727

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
