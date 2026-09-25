# JSON parser for C

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=1.53.0
libs_rev=1
libs_url=https://github.com/libuv/libuv/archive/refs/tags/v1.53.0.tar.gz
libs_sha=279f3f67a24bb9921fe999ca6cd5e332fade8d515873ef9ba054b70e70a31d9e

libs_args=(

    -DLIBUV_BUILD_SHARED=OFF
)

libs_build() {
    # not everyone support '-l:libuv.a'
    sed -i 's/-l:libuv.a/-luv/g' libuv-static.pc.in

    cmake.setup

    cmake.build

    cmdlet.pkgfile $libs_name -- cmake.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
