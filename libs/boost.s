# Collection of portable C++ source libraries

# shellcheck disable=SC2034
libs_lic='BSL-1.0'
libs_ver=1.90.0
libs_url=https://github.com/boostorg/boost/releases/download/boost-1.90.0/boost-1.90.0-b2-nodocs.tar.xz
libs_sha=9e6bee9ab529fb2b0733049692d57d10a72202af085e553539a05b4204211a6f
libs_dep=( zlib bzip2 xz zstd )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-shared
    --enable-static
)

libs_build() {
    # Force boost to compile with the desired compiler
    if is_darwin; then
        echo "using darwin : : $CXX ;" > user-config.jam
    else
        echo "using gcc : : $CXX ;" > user-config.jam
    fi

    slogcmd ./bootstrap.sh                  \
        --prefix="'$PREFIX'"                \
        --libdir="'$PREFIX/lib'"            \
        --without-icu                       \
        --without-libraries='python,mpi,log'

    slogcmd ./b2 headers

    # no DESTDIR support
    slogcmd ./b2 install -d2                \
        --prefix="'$PREFIX'"                \
        --libdir="'$PREFIX/lib'"            \
        --layout=system                     \
        --user-config=user-config.jam       \
        threading=multi                     \
        link=static                         \
        runtime-link=static

    pkgfile libboost include/boost lib/libboost_*.a
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
