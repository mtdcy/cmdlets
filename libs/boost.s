# Collection of portable C++ source libraries

# shellcheck disable=SC2034
libs_lic='BSL-1.0'
libs_ver=1.90.0
libs_url=https://github.com/boostorg/boost/releases/download/boost-1.90.0/boost-1.90.0-b2-nodocs.tar.xz
libs_sha=9e6bee9ab529fb2b0733049692d57d10a72202af085e553539a05b4204211a6f

libs_deps=( zlib bzip2 xz zstd )

libs_args=(
    --prefix="'$PREFIX'"
    --libdir="'$PREFIX/lib'"
)

# XXX: no pc files, add -DBoost_USE_STATIC_LIBS=ON to cmake manually when link with static boost
libs_build() {

    # build b2 for host, unset target variables
    SAVED_WINDRES="$WINDRES"
    unset WINDRES

    slogcmd ./bootstrap.sh "${libs_args[@]}"        \
        --with-toolset="gcc"                        \
        --without-icu                               \
        --without-libraries='python,mpi,log'        \
        || die "bootstrap failed."

    export WINDRES="$SAVED_WINDRES"

    # Force boost to compile with the desired compiler
    if is_darwin; then
        echo "using darwin : : $CXX ;" > user-config.jam
    else
        echo "using gcc : : $CXX ;"    > user-config.jam
    fi

    #is_posix && libs_args+=( define=BOOST_THREAD_POSIX )
    if is_darwin; then
        libs_args+=( target-os=darwin )
    elif is_mingw; then
        libs_args+=( target-os=windows abi=ms )
    else
        libs_args+=( target-os=linux )
    fi

    case "$(uname -m)" in
        x86_64|aarch64|arm64)
            libs_args+=( address-model=64 )
            ;;
        *)
            libs_args+=( address-model=32 )
            ;;
    esac

    is_listed zlib  libs_deps || libs_args+=( -sNO_ZLIB=1 )
    is_listed bzip2 libs_deps || libs_args+=( -sNO_BZIP2=1 )

    slogcmd ./b2 headers "${libs_args[@]}"          \
        || die "b2 headers failed."

    # no DESTDIR support
    slogcmd ./b2 install "${libs_args[@]}"          \
        -d1 -q                                      \
        --layout=system                             \
        --user-config=user-config.jam               \
        variant=release                             \
        threading=multi                             \
        link=static                                 \
        runtime-link=static                         \
        || die "b2 install failed."

    pkgfile libboost include/boost lib/libboost_*.a
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
