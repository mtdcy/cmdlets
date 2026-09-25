# Simple DirectMedia Layer core library
#
# shellcheck disable=SC2034
libs_lic="Zlib"
libs_ver=3.4.16
libs_rev=1
libs_url=https://github.com/libsdl-org/SDL/releases/download/release-$libs_ver/SDL3-$libs_ver.tar.gz
libs_sha=7322236cd12090c3eb40b9728be4d49c76f66ad17d04369584d4ecad5cf77c68

libs_args=(
    # static only
    -DBUILD_SHARED_LIBS=OFF

    -DSDL_JACK=OFF
    -DSDL_SNDIO=OFF

    -DSDL_TESTS=OFF
    -DSDL_X11_XTEST=OFF

    # console without windows for now
    -DSDL_UNIX_CONSOLE_BUILD=ON
)

is_cygwin && libs_patches+=(
    https://cygwin.com/cgit/cygwin-packages/SDL3/plain/SDL3-3.4.16-1.src.patch
)

libs_build() {

    cmake.setup

    cmake.build

    cmdlet.pkgfile libSDL3 -- cmake.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
