# Library of 2D and 3D vector, matrix, and math operations

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=3.2.2
libs_url=https://github.com/AcademySoftwareFoundation/Imath/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=b4275d83fb95521510e389b8d13af10298ed5bed1c8e13efd961d91b1105e462
libs_dep=( )

# configure args
libs_args=(
    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    mkdir -p build && cd build 

    cmake .. && make || return 1

    pkgfile libImath -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
