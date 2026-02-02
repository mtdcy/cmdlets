# shellcheck disable=SC2034
libs_desc="Performance-portable, length-agnostic SIMD with runtime dispatch"
libs_lic="Apache-2.0"

libs_ver=1.3.0
libs_url=https://github.com/google/highway/archive/refs/tags/1.3.0.tar.gz
libs_sha=07b3c1ba2c1096878a85a31a5b9b3757427af963b1141ca904db2f9f4afe0bc2
libs_dep=( )

libs_args=(
    -DHWY_ENABLE_TESTS=OFF
    -DHWY_ENABLE_EXAMPLES=OFF

    # static only
    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    rm -f BUILD

    cmake.setup

    cmake.build

    cmdlet.pkgfile libhwy -- cmake.install --component Unspecified
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
