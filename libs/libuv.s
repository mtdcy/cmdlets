# JSON parser for C

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=1.51.0
libs_url=https://github.com/libuv/libuv/archive/refs/tags/v1.51.0.tar.gz
libs_sha=27e55cf7083913bfb6826ca78cde9de7647cded648d35f24163f2d31bb9f51cd

libs_args=(

    -DLIBUV_BUILD_SHARED=OFF
)

libs_build() {
    cmake -S . -B build

    cmake --build build

    pkgfile $libs_name -- cmake --install build
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
