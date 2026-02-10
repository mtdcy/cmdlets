# Liquid Rescale Library: a seam-carving C/C++ library
#  resizing pictures non uniformly while preserving their features
#
# shellcheck disable=SC2034

libs_lic='LGPL-3.0-only'
libs_ver=0.4.3
libs_url=https://github.com/carlobaldassi/liblqr/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=64b0c4ac76d39cca79501b3f53544af3fc5f72b536ac0f28d2928319bfab6def
libs_dep=( glib )

is_darwin && libs_patches=(
    https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff
)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # disabled features
    --without-gettext
    --disable-install-man

    # static
    --disable-shared
    --enable-static
)

libs_build() {
    configure 

    make 

    is_mingw && pkgconf lqr-1.pc -DLQR_DISABLE_DECLSPEC

    pkgfile liblqr -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
