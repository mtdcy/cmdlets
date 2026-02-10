# Library for manipulating PNG images
#
# shellcheck disable=SC2034

libs_lic="libpng-2.0"
libs_ver=1.6.55
libs_url=https://downloads.sourceforge.net/libpng/libpng16/libpng-$libs_ver.tar.xz
libs_sha=d925722864837ad5ae2a82070d4b2e0603dc72af44bd457c3962298258b8e82d
libs_dep=(zlib)

libs_args=(
    --disable-option-checking
    --enable-silent-rules

    --enable-hardware-optimizations

    --enable-unversioned-links
    --enable-unversioned-libpng-pc

    --enable-pic

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    # fix libpng-config
    #  1. always static
    sed -i libpng16-config \
        -e 's/\${libs}/\${all_libs}/g'

    pkgfile libpng -- make.install bin_PROGRAMS=

    for x in pngfix pngtest pngimage png-fix-itxt; do
        cmdlet.install "$x"
    done

    cmdlet.check pngtest
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
