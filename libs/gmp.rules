# GNU multiple precision arithmetic library
#
# shellcheck disable=SC2034

libs_lic='LGPLv3+|GPLv2+'
libs_ver=6.3.0
libs_rev=1

# gmplib.org blocks GitHub server IPs, so it should not be the primary URL
libs_url=${LIBS_MIRROR_GNU:-https://ftpmirror.gnu.org/gnu}/gmp/gmp-$libs_ver.tar.xz
libs_sha=a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898

libs_deps=()

# bad patch level, use libs_resources instead
is_mingw && libs_patches=(
    https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-gmp/do-not-use-dllimport.diff
    https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-gmp/gmp-staticlib.diff
)

libs_args=(
    # static only
    --enable-static --disable-shared

    --enable-cxx
)

if is_mingw; then
    # fix undefined symbol 'foo'
    libs_args+=(--disable-assembly)
else
    is_intel && libs_args+=(--enable-fat) || libs_args+=(--disable-assembly)
fi

libs_build() {
    # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-gmp/PKGBUILD
    libs.requires -Wno-attributes -Wno-ignored-attributes

    bootstrap

    # CC_FOR_BUILD : configure: error: Cannot determine executable suffix
    CC_FOR_BUILD="$HOSTCC" configure

    make

    make check

    cmdlet.pkgfile libgmp -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
