
#
# shellcheck disable=SC2034
libs_lic="GPL"
libs_ver=2023.12.14
libs_url=https://github.com/KhronosGroup/OpenCL-Headers/archive/refs/tags/v$libs_ver.zip
libs_zip=OpenCL-Headers-$libs_ver.zip
libs_sha=cc55c351b1b71346469c7ecdec3d62ad6661b2e3c41b9df165ee8b1ab75563d3

libs_build() {
    cmake . && make && make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
