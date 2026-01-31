# OpenCL ICD Loader
#
# shellcheck disable=SC2034
libs_lic="GPL"
libs_ver=2025.07.22
libs_url=https://github.com/KhronosGroup/OpenCL-ICD-Loader/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=dff7a0b11ad5b63a669358e3476e3dc889a4a361674e5b69b267b944d0794142

libs_resources=(
    # OpenCL-Headers
    "https://github.com/KhronosGroup/OpenCL-Headers/archive/refs/tags/v$libs_ver.zip;ef9ba8d4231110bb369becb20cb98259d94a448fc8232ede96551c26d110840f"
)

libs_args=(
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_TESTING=OFF
)

libs_build() {
    # build OpenCL Headers
    pushd OpenCL-Headers-$libs_ver

    cmake.setup

    cmake.build

    pkgfile libOpenCLHeaders -- cmake.install

    popd

    # build OpenCL ICD Loader
    cmake.setup

    cmake.build

    pkgfile libOpenCL -- cmake.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
