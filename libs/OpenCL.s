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

# shellcheck disable=SC2086
libs_build() {
    (
        # build OpenCL Headers
        pushd OpenCL-Headers-$libs_ver || die

        # set right place for pkgconfig file
        sed -i cmake/Package.cmake \
            -e '/pkg_config_location/s/CMAKE_INSTALL_DATADIR/CMAKE_INSTALL_LIBDIR/'

        cmake.setup

        cmake.build

        pkgfile libOpenCLHeaders -- cmake.install

    ) || die "Build OpenCL Headers failed."

    if is_mingw; then
        # always build as libOpenCL.a
        sed -i CMakeLists.txt \
            -e '/OpenCL PROPERTIES PREFIX ""/d' 
    fi

    # build OpenCL ICD Loader
    cmake.setup

    cmake.build

    # fix linked win32 libraries
    is_mingw && pkgconf pkgconfig_install/OpenCL.pc -lcfgmgr32 -lruntimeobject -lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32 -luuid -lcomdlg32 -ladvapi32

    pkgfile libOpenCL -- cmake.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
