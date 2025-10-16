# C library for encoding, decoding, and manipulating JSON

# shellcheck disable=SC2034
libs_name=jansson
libs_lic="MIT"
libs_ver=2.14
libs_url=https://github.com/akheron/jansson/releases/download/v$libs_ver/jansson-$libs_ver.tar.gz
libs_sha=c739578bf6b764aa0752db9a2fdadcfe921c78f1228c7ec0bb47fa804c55d17b

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    configure && make || return $?

    pkgfile libjansson -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
