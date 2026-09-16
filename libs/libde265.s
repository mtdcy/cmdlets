# Open h.265 video codec implementation.

# shellcheck disable=SC2034
libs_ver=1.1.3
libs_rev=1
libs_url=https://github.com/strukturag/libde265/releases/download/v$libs_ver/libde265-$libs_ver.tar.gz
libs_sha=554228bd17788c99a7e63b37ab5634722190e6e2bf60c1dcb01cef328e133905
libs_dep=()

# Fix -flat_namespace being used on Big Sur and later. <= homebrew
#is_darwin && libs_patches=(
#    https://raw.githubusercontent.com/Homebrew/formula-patches/03cf8088210822aa2c1ab544ed58ea04c897d9c4/libtool/configure-big_sur.diff
#)

# configure args
libs_args=(
    # 纯粹的解码定位
    # decode only for libheif
    -DENABLE_DECODER=ON
    -DENABLE_ENCODER=OFF
    -DENABLE_SHERLOCK265=OFF

    -DENABLE_SDL=OFF

    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    # fix error: 'alloca' was not declared in this scope
    libs.conftest alloca.h && libs.requires -DHAVE_ALLOCA_H
    # error: 'posix_memalign' was not declared in this scope
    is_posix && libs.requires -D_POSIX_C_SOURCE=200112L

    cmake.setup

    cmake.build

    cmdlet.pkgconf libde265/libde265.pc -DLIBDE265_STATIC_BUILD

    cmdlet.pkgfile libde265 -- cmake.install --install libde265

    cmdlet.install dec265/dec265

    cmdlet.verify -- dec265 --help
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
