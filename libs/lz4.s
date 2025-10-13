# Extremely Fast Compression algorithm
# shellcheck disable=SC2034

libs_name=lz4
libs_lic="BSD-2-Clause"
libs_ver=1.10.0
libs_url=https://github.com/lz4/lz4/releases/download/v$libs_ver/lz4-$libs_ver.tar.gz
libs_sha=537512904744b35e232912055ccf8ec66d768639ff3abe5788d90d792ec5f48b
libs_dep=()

libs_args=(
)

libs_build() {
    sed -e 's/^BUILD_SHARED.*:=.*$/BUILD_SHARED:=no/' \
        -i lib/Makefile &&

    make &&

    make -C lib liblz4.pc &&

    library liblz4 \
            include lib/*.h \
            lib     lib/liblz4.a \
            lib/pkgconfig lib/liblz4.pc &&

    cmdlet  ./lz4 lz4 lz4c lz4cat &&

    check lz4
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
