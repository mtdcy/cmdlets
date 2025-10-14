#  Ultralightweight JSON parser in ANSI C

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=1.7.19
libs_url=https://github.com/DaveGamble/cJSON/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=7fa616e3046edfa7a28a32d5f9eacfd23f92900fe1f8ccd988c1662f30454562

libs_args=(
    -DENABLE_CJSON_UTILS=ON
    -DENABLE_CJSON_TEST=OFF

    -DBUILD_SHARED_LIBS=OFF
    -DCJSON_BUILD_SHARED_LIBS=OFF
)

libs_build() {
    mkdir -p build && cd build && cmake .. && make || return 1

    pkgfile libcjson                  \
            include/cjson/*           \
            lib/libcjson*.a           \
            lib/pkgconfig/libcjson.pc \
            lib/cmake/cJSON/*.cmake   \
            &&
    
    inspect make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
