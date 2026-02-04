# Generic-purpose lossless compression algorithm by Google
#
# shellcheck disable=SC2034

libs_lic="MIT"
libs_ver=1.2.0
libs_url=https://github.com/google/brotli/archive/refs/tags/v1.2.0.tar.gz
libs_sha=816c96e8e8f193b40151dad7e8ff37b1221d019dbcb9c35cd3fadbfe6477dfec
libs_dep=()

libs_args=(
    -DBROTLI_BUILD_TOOLS=OFF

    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {

    cmake.setup

    cmake.build

    pkgfile libbrotli -- cmake.install --component Unspecified
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
