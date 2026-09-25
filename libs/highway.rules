# shellcheck disable=SC2034
libs_desc="Performance-portable, length-agnostic SIMD with runtime dispatch"
libs_lic="Apache-2.0"

libs_ver=1.4.0
libs_url=https://github.com/google/highway/archive/refs/tags/1.4.0.tar.gz
libs_sha=e72241ac9524bb653ae52ced768b508045d4438726a303f10181a38f764a453c
libs_dep=( )

libs_args=(
    -DHWY_ENABLE_TESTS=OFF
    -DHWY_ENABLE_EXAMPLES=OFF

    # static only
    -DHWY_FORCE_STATIC_LIBS=ON
    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    cmake.setup

    cmake.build

    cmdlet.pkgfile libhwy -- cmake.install --component Unspecified
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
