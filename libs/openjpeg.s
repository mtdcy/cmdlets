# OpenJPEG is an open-source JPEG 2000 codec written in C language.
#
# shellcheck disable=SC2034

libs_ver=2.5.4
libs_url=https://github.com/uclouvain/openjpeg/archive/v$libs_ver.tar.gz
libs_sha=a695fbe19c0165f295a8531b1e4e855cd94d0875d2f88ec4b61080677e27188a
libs_dep=( )

libs_args=(
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_STATIC_LIBS=ON

    -DBUILD_DOC=OFF

    # no applications
    -DBUILD_CODEC=OFF
)

libs_build() {
    cmake . && make || return $?

    pkgfile libopenjp2 -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
