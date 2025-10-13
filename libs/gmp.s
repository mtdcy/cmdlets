# GNU multiple precision arithmetic library
#
# shellcheck disable=SC2034

libs_lic='LGPL-3.0-or-later|GPL-2.0-or-later'
libs_ver=6.3.0

# gmplib.org blocks GitHub server IPs, so it should not be the primary URL
libs_url=https://mirrors.ustc.edu.cn/gnu/gmp/gmp-$libs_ver.tar.xz
#https://ftpmirror.gnu.org/gnu/gmp/gmp-$libs_ver.tar.xz
libs_sha=a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-cxx
    --with-pic

    --disable-shared
    --enable-static
)

libs_build() {
    is_darwin || export CXXFLAGS+=" -static-libstdc++"

    configure &&

    make &&

    #make check &&

    library libgmp:libgmpxx \
            include         gmp.h gmpxx.h \
            lib             .libs/libgmp*.{a,la} \
            lib/pkgconfig   gmp.pc gmpxx.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
