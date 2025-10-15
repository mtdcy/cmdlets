# LLVM's OpenMP runtime library (macOS only)

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=21.1.3
libs_url=https://github.com/llvm/llvm-project/releases/download/llvmorg-$libs_ver/openmp-$libs_ver.src.tar.xz
libs_sha=a3f6af3d9e80ec6217e92675d4253db85f006d788943b8ccacf18bde23d2b816
libs_dep=( )

# cmake
libs_patch_url=(
    https://github.com/llvm/llvm-project/releases/download/llvmorg-$libs_ver/cmake-$libs_ver.src.tar.xz
)
libs_patch_sha=(
    4db6f028b6fe360f0aeae6e921b2bd2613400364985450a6d3e6749b74bf733a
 )

# configure args
libs_args=(
    # install as libgomp?
    -DLIBOMP_INSTALL_ALIASES=OFF

    -DCMAKE_MODULE_PATH=

    # static
    -DLIBOMP_ENABLE_SHARED=OFF
)

libs_build() {
    if ! is_darwin; then
        slogw "openmp is for macOS only"
        return 0
    fi

    mv Modules/*.cmake cmake/

    mkdir -p build && cd build

    cmake .. && make || return 1

    inspect make install 

    pkgfile libomp \
            include/omp*.h \
            lib/libomp.a 
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
