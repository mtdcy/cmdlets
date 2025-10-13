# shellcheck disable=SC2034

libs_name=lzop
libs_desc="lzop is a file compressor which is very similar to gzip."

libs_lic='GPL-2.0'
libs_ver=1.04
libs_url=https://www.lzop.org/download/lzop-$libs_ver.tar.gz
libs_sha=7e72b62a8a60aff5200a047eea0773a8fb205caf7acbe1774d95147f305a2f41
libs_dep=(lzo)

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --enable-silent-rules

)

libs_build() {
    # force use configure
    rm -f CMakeLists.txt || true

    configure &&

    make V=1 &&

    make check &&

    cmdlet src/lzop &&

    # visual verify
    check lzop --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
