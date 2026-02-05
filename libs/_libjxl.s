# shellcheck disable=SC2034
libs_desc="JPEG XL image format reference implementation"
libs_lic="BSD-3-Clause"

libs_ver=0.11.1
libs_url=https://github.com/libjxl/libjxl/archive/refs/tags/v0.11.1.tar.gz
libs_sha=1492dfef8dd6c3036446ac3b340005d92ab92f7d48ee3271b5dac1d36945d3d9
libs_dep=( brotli lcms2 highway giflib imath libjpeg-turbo libpng )

libs_args=(
    -DJPEGXL_FORCE_SYSTEM_BROTLI=ON
    -DJPEGXL_FORCE_SYSTEM_LCMS2=ON
    -DJPEGXL_FORCE_SYSTEM_HWY=ON

    -DJPEGXL_ENABLE_SJPEG=OFF   # FIXME
    -DJPEGXL_ENABLE_OPENEXR=OFF
    -DJPEGXL_ENABLE_JNI=OFF     # JNI java wrapper
    -DJPEGXL_ENABLE_JPEGLI=OFF
    -DJPEGXL_ENABLE_SKCMS=OFF   # use lcms2 instead
    -DJPEGXL_ENABLE_SJPEG=OFF

    -DJPEGXL_VERSION="$libs_ver"

    -DJPEGXL_ENABLE_BENCHMARK=OFF
    -DJPEGXL_ENABLE_EXAMPLES=OFF
    -DJPEGXL_ENABLE_MANPAGES=OFF
    -DJPEGXL_ENABLE_DOXYGEN=OFF
    -DJPEGXL_ENABLE_PLUGINS=OFF
    -DBUILD_TESTING=OFF

    # static only
    -DBUILD_SHARED_LIBS=OFF

    # ld: library 'crt0.o' not found
    -DJPEGXL_ENABLE_TOOLS=OFF
    #-DJPEGXL_STATIC=ON

    # Could NOT find Threads
    -DCMAKE_USE_PTHREADS_INIT=1
)

is_arm64 && libs_args+=( -DJPEGXL_FORCE_NEON=ON )

libs_build() {

    cmake.setup

    cmake.build

    cmdlet.pkgfile libjxl -- cmake.install --component Unspecified
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
