# Zstandard is a real-time compression algorithm
# shellcheck disable=SC2034

libs_lic="BSD|GPLv2"
libs_ver=1.5.7
libs_url=https://github.com/facebook/zstd/releases/download/v$libs_ver/zstd-$libs_ver.tar.gz
libs_sha=eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3

libs_deps=(zlib xz lz4)
libs_args=(
    -DZSTD_BUILD_CONTRIB=ON
    -DZSTD_LEGACY_SUPPORT=ON
    -DZSTD_ZLIB_SUPPORT=ON
    -DZSTD_LZMA_SUPPORT=ON
    -DZSTD_LZ4_SUPPORT=ON
    -DCMAKE_CXX_STANDARD=11
    -DZSTD_BUILD_STATIC=ON
    -DZSTD_BUILD_SHARED=OFF
    -DZSTD_PROGRAMS_LINK_SHARED=OFF
)

libs_build() {
    pushd build/cmake 

    cmake .

    make tests

    cmdlet.pkgfile libzstd -- make install -C lib

    cmdlet.pkgfile zstd    -- make install -C programs

    cmdlet.check zstd --version
    
    # simple test 
    echo "test" > foo && rm -f foo.zst
    run zstd foo                                || die "zstd compress failed."
    run zstd -t foo.zst                         || die "zstd integrity test failed."
    run zstd -l foo.zst | grep -Fwq foo         || die "zstd list contents failed."
    run zstd -d -c foo.zst | grep -Eq "^test$"  || die "zstd decompress failed."
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
