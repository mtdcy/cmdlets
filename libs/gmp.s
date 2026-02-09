# GNU multiple precision arithmetic library
#
# shellcheck disable=SC2034

libs_lic='LGPLv3+|GPLv2+'
libs_ver=6.3.0

# gmplib.org blocks GitHub server IPs, so it should not be the primary URL
libs_url=(
    https://mirrors.ustc.edu.cn/gnu/gmp/gmp-$libs_ver.tar.xz
    https://ftpmirror.gnu.org/gnu/gmp/gmp-$libs_ver.tar.xz
)
libs_sha=a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898
libs_dep=()

# bad patch level, use libs_resources instead
is_mingw && libs_resources=(
    https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-gmp/do-not-use-dllimport.diff
    https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-gmp/gmp-staticlib.diff
)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-cxx

    # static only
    --disable-shared
    --enable-static
)

is_arm64 && libs_args+=( --disable-assembly )

libs_build() {
    # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-gmp/PKGBUILD
    export CFLAGS+=" -Wno-attributes -Wno-ignored-attributes"

    if is_mingw; then
        slogcmd patch -Np2 -i do-not-use-dllimport.diff
        slogcmd patch -Np1 -i gmp-staticlib.diff

        #libs_args+=( --build="$_TARGET" )
    fi

    bootstrap

    # CC_FOR_BUILD  : configure: error: Cannot determine executable suffix
    CC_FOR_BUILD=gcc configure

    make

    make check

    pkgfile libgmp -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
