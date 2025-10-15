# Open h.265 video decoder

# shellcheck disable=SC2034
libs_ver=1.0.16
libs_url=https://github.com/strukturag/libde265/releases/download/v$libs_ver/libde265-$libs_ver.tar.gz
libs_sha=b92beb6b53c346db9a8fae968d686ab706240099cdd5aff87777362d668b0de7
libs_dep=( sdl2 )

# Fix -flat_namespace being used on Big Sur and later. <= homebrew
is_darwin && libs_patches=(
    https://raw.githubusercontent.com/Homebrew/formula-patches/03cf8088210822aa2c1ab544ed58ea04c897d9c4/libtool/configure-big_sur.diff
)

# configure args
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --disable-sherlock265
    --disable-dec265         # needs sdl2
   
    # static
    --disable-shared
    --enable-static
)

libs_build() {
    if is_darwin && is_arm64; then
        libs_args+=( --build=aarch64-apple-darwin )
    fi
    
    is_darwin || export CXXFLAGS+=" -static-libstdc++"

    # no tools
    sed -i '/SUBDIRS+=tools/d' Makefile.am

    configure && make || return 1

    inspect make install &&

    pkgfile libde265                  \
            include/libde265          \
            lib/libde265.a            \
            lib/pkgconfig/libde265.pc

    # FIXME: can not find where is wrong
    #  attempted static link of dynamic object `.../libstdc++.so'
    #cmdlet  ./dec265/dec265 &&

    #check dec265 --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
