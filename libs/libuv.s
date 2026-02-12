# JSON parser for C

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=1.52.0
libs_url=https://github.com/libuv/libuv/archive/refs/tags/v1.52.0.tar.gz
libs_sha=eee139c05f7c868f5ae7a54b1e155fd5b6ed13a22329958d2ba711faad016353

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
