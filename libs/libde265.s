# Open h.265 video decoder

# shellcheck disable=SC2034
libs_ver=1.0.16
libs_url=https://github.com/strukturag/libde265/releases/download/v$libs_ver/libde265-$libs_ver.tar.gz
libs_sha=b92beb6b53c346db9a8fae968d686ab706240099cdd5aff87777362d668b0de7
libs_dep=( )

# Fix -flat_namespace being used on Big Sur and later. <= homebrew
is_darwin && libs_patches=(
    https://raw.githubusercontent.com/Homebrew/formula-patches/03cf8088210822aa2c1ab544ed58ea04c897d9c4/libtool/configure-big_sur.diff
)

# configure args
libs_args=(
    # decode only for libheif
    -DENABLE_DECODER=ON
    -DENABLE_ENCODER=OFF

    -DENABLE_SDL=OFF

    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {

    cmake.setup

    cmake.build

    pkgfile libde265 -- cmake.install --install libde265

    cmdlet.install dec265/dec265

    check dec265 --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
