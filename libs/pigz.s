# shellcheck disable=SC2034
libs_desc="Parallel gzip"
libs_lic='Zlib'
libs_ver=2.8
libs_url=(
    https://zlib.net/pigz/pigz-$libs_ver.tar.gz
)
libs_sha=eb872b4f0e1f0ebe59c9f7bd8c506c4204893ba6a8492de31df416f0d5170fd0
libs_dep=( zlib zopfli )

libs_args=(
    CC="'$CC'"
    CFLAGS="'$CFLAGS $CPPFLAGS'"
    LDFLAGS="'$LDFLAGS'"
    ZOP="'$PREFIX/lib/libzopfli.a'"
)

libs_build() {
    # ln pigz without ext won't work with mingw
    sed -i '/ln -f pigz/d' Makefile

    make "${libs_args[@]}"

    cmdlet.install pigz pigz unpigz

    cmdlet.check pigz

    caveats << EOF
static built pigz @ $libs_ver

Usage:
    tar -cf - paths-to-archive  | pigz --best -p 8 > archive.tar.gz
    unpigz -d archive.tar.gz    | tar -xf -

    OR

    tar -I pigz -xf archive.tar.gz -C /tmp
    tar -I pigz -cf archive.tar.gz -C /opt
EOF
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
