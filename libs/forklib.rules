# forklib from winnie for Windows 10+
#
# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.3.0
libs_url=https://github.com/ergrelet/forklib/archive/refs/tags/0.3.0.tar.gz
libs_sha=a3ebba63f5c772d92f6dffdbf979fe05b985aae84c6d8c8cd64abd083fedd4c8

libs_deps=( cppwinrt )

# configure args
libs_args=(

    -DFORKLIB_BUILD_SHARED_LIB=OFF
)

libs_build() {
    sed -i src/targetver.h \
        -e 's/SDKDDKVer.h/sdkddkver.h/g'

    sed -i CMakeLists.txt \
        -e '/wow64ext/d'

    cmake.setup

    cmake.build

    cmdlet.pkgfile libfork -- cmake.install --component Unspecified
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
