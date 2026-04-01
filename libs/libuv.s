# JSON parser for C

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=1.52.1
libs_url=https://github.com/libuv/libuv/archive/refs/tags/v1.52.1.tar.gz
libs_sha=478baf2599bfbc882c355288c9cb6f92e0e7dda435fa04031fa5b607cf3f414c

libs_args=(

    -DLIBUV_BUILD_SHARED=OFF
)

libs_build() {
    # not everyone support '-l:libuv.a'
    sed -i 's/-l:libuv.a/-luv/g' libuv-static.pc.in

    cmake -S . -B build

    cmake --build build

    pkgfile $libs_name -- cmake --install build
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
