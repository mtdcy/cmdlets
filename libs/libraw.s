# Library for reading RAW files from digital photo cameras

# shellcheck disable=SC2034
libs_ver=0.21.4
libs_url=https://www.libraw.org/data/LibRaw-$libs_ver.tar.gz
libs_sha=6be43f19397e43214ff56aab056bf3ff4925ca14012ce5a1538a172406a09e63
libs_dep=( zlib libjpeg-turbo lcms2 )

# configure args
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-jpeg
    --enable-zlib
    --enable-lcms      # color management

    # prefer openjpeg
    --disable-jasper     # JPEG-2000

    # not ready
    --disable-openmp

    --disable-examples
    --disable-docs

    --disable-shared
    --enable-static
)

#if is_darwin; then
#    #libs_args+=(
#    #    ## Work around checking for clang option to support OpenMP... unsupported
#    #    #ac_cv_prog_c_openmp="'-Xpreprocessor -fopenmp'"
#    #    #ac_cv_prog_cxx_openmp="'-Xpreprocessor -fopenmp'"
#    #)
#    #export LDFLAGS+=" -lomp -lz"
#fi

libs_build() {
    slogcmd autoreconf -fiv || return 1

    configure && make || return 2

    inspect make install &&

    pkgfile libraw                   \
            include/libraw           \
            lib/libraw*.a            \
            lib/pkgconfig/libraw*.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
