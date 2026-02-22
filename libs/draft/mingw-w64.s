# Minimalist GNU for Windows

# build only for linux
libs_targets=( linux )

# shellcheck disable=SC2034
libs_lic=ZPLv2.1
libs_ver=13.0.0
libs_url=https://downloads.sourceforge.net/project/mingw-w64/mingw-w64/mingw-w64-release/mingw-w64-v13.0.0.tar.bz2
libs_sha=5afe822af5c4edbf67daaf45eec61d538f49eef6b19524de64897c6b95828caf

libs_deps=( gmp isl mpc mpfr zlib zstd )

libs_resources=(
    https://ftpmirror.gnu.org/gnu/binutils/binutils-2.45.tar.bz2
    https://ftpmirror.gnu.org/gnu/gcc/gcc-15.2.0/gcc-15.2.0.tar.xz
)

# choice: mingw64, cygwin, msys2
MinGW_w64_target=mingw32

libs_build() {

    local _mingw_target=$(uname -m)-w64-mingw32
    local _mingw_sysroot="$PREFIX/share/mingw64"


    # build binutils
    pushd binutils-*

    configure                                             \
        --target=$_mingw_target                           \
        --enable-targets=$_mingw_target                   \
        --prefix="$_mingw_sysroot"                        \
        --with-sysroot="$_mingw_sysroot"                  \
        --disable-multilib                                \
        --disable-nls                                     \
        --with-system-zlib                                \
        --with-zstd                                       \

    make

    make.install

    popd

    # create a mingw symlink
    ln -sfv "$_mingw_target" "$_mingw_sysroot/mingw"

    # build mingw-w64-headers
    pushd mingw-w64-headers

    configure --prefix="$_mingw_sysroot/mingw"

    make

    make.install

    popd

    # build stage gcc
    pushd gcc-*

    configure                                             \
        --target=$_mingw_target                           \
        --with-sysroot="$_mingw_sysroot"                  \
        --prefix="$_mingw_sysroot"                        \
        --enable-languages=c,c++,objc,obj-c++             \
        --with-ld="$_mingw_sysroot/bin/$_mingw_target-ld" \
        --with-as="$_mingw_sysroot/bin/$_mingw_target-as" \
        --with-gmp="'$PREFIX'"                            \
        --with-mpfr="'$PREFIX'"                           \
        --with-mpc="'$PREFIX'"                            \
        --with-isl="'$PREFIX'"                            \
        --with-system-zlib                                \
        --with-zstd                                       \
        --disable-multilib                                \
        --disable-nls                                     \
        --enable-threads=posix                            \

    make all-gcc

    make install-gcc

    popd

    export LD="$_mingw_sysroot/bin/$_mingw_target-ld"
    export AS="$_mingw_sysroot/bin/$_mingw_target-AS"
    export CC="$_mingw_sysroot/bin/$_mingw_target-gcc"
    export CXX="$_mingw_sysroot/bin/$_mingw_target-g++"
    export CPP="$_mingw_sysroot/bin/$_mingw_target-cpp"

    # build mingw-w64-crt - mingw-w64 runtime
    pushd mingw-w64-crt

    configure                                             \
        --host=$_mingw_target                             \
        --with-sysroot="'$_mingw_sysroot/mingw'"          \
        --prefix="'$_mingw_sysroot/mingw'"                \
        --enable-lib64 --disable-lib32                    \

    # -j1: Too many open files in system
    make -j1
    make.install

    popd

    _mingw_args=(
        --host=$_mingw_target
        --with-sysroot="'$_mingw_sysroot/mingw'"
        --prefix="'$_mingw_sysroot/mingw'"
        --program-prefix=$_mingw_target-
    )

    _mingw_build() {
        pushd "$1"
        configure "${_mingw_args[@]}" "${@:2}"
        make
        make.install
        popd
    }

    _mingw_build mingw-w64-libraries/winpthreads
    _mingw_build mingw-w64-tools/widl

    # finish gcc build (runtime libraries)
    pushd gcc-*
    make
    make.install
    popd
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
