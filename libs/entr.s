# Run arbitrary commands when files change

# shellcheck disable=SC2034
libs_lic=ISC
libs_ver=5.7
libs_url=https://eradman.com/entrproject/code/entr-5.7.tar.gz
libs_sha=90c5d943820c70cef37eb41a382a6ea4f5dd7fd95efef13b2b5520d320f5d067
libs_dep=( )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-debug
    --disable-doxygen-doc

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    cmdlet.install entr

    cmdlet.check entr
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
