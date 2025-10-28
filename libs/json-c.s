# JSON parser for C

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=0.18
libs_url=https://github.com/json-c/json-c/archive/refs/tags/json-c-0.18-20240915.tar.gz
libs_sha=3112c1f25d39eca661fe3fc663431e130cc6e2f900c081738317fba49d29e298

libs_args=(
    # We pass `BUILD_APPS=OFF` since any built apps are never installed. See:
    #   https://github.com/json-c/json-c/blob/master/apps/CMakeLists.txt#L119-L121
    -DBUILD_APPS=OFF

    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_STATIC_LIBS=ON
)

libs_build() {
    cmake -S . -B build

    cmake --build build

    pkgfile libjson-c -- cmake --install build
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
