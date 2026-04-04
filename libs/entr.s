# Run arbitrary commands when files change

# shellcheck disable=SC2034
libs_lic=ISC
libs_ver=5.8
libs_url=https://eradman.com/entrproject/code/entr-5.8.tar.gz
libs_sha=dc9a2bdc556b2be900c1d8cdf432de26492de5af3ffade000d4bfd97f3122bfb
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
