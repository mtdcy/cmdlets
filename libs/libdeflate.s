# Heavily optimized DEFLATE/zlib/gzip compression and decompression

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.25
libs_url=https://github.com/ebiggers/libdeflate/archive/refs/tags/v1.25.tar.gz
libs_sha=d11473c1ad4c57d874695e8026865e38b47116bbcb872bfc622ec8f37a86017d
libs_dep=( )

libs_args=(

    # features
    -DLIBDEFLATE_ZLIB_SUPPORT=ON
    -DLIBDEFLATE_GZIP_SUPPORT=ON
    -DLIBDEFLATE_COMPRESSION_SUPPORT=ON
    -DLIBDEFLATE_DECOMPRESSION_SUPPORT=ON

    # tools
    -DLIBDEFLATE_BUILD_GZIP=ON      # libdeflate-gzip

    # disabled features
    -DLIBDEFLATE_BUILD_TESTS=OFF

    # static only
    -DLIBDEFLATE_BUILD_STATIC_LIB=ON
    -DLIBDEFLATE_BUILD_SHARED_LIB=OFF
    -DLIBDEFLATE_USE_SHARED_LIB=OFF
)

is_darwin && libs_args+=( -DLIBDEFLATE_APPLE_FRAMEWORK=OFF )

libs_build() {

    cmake.setup

    cmake.build

    # cmake install libdeflate-gunzip as hard link
    #cmdlet.pkgfile libdeflate -- cmake.install --component Unspecified
    cmdlet.pkginst libdeflate                                             \
        include                 ../libdeflate.h                           \
        lib                     libdeflate.a                              \
        lib/pkgconfig           libdeflate.pc                             \
        lib/cmake/libdeflate    $(find . -name "libdeflate-*.cmake" | xargs)

    cmdlet.install programs/libdeflate-gzip libdeflate-gzip libdeflate-gunzip

    cmdlet.check libdeflate-gzip
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
