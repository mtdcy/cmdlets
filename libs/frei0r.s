# free video effect plugin collection

# shellcheck disable=SC2034
libs_lic="GPLv2"
libs_ver=2.5.6
libs_url=https://github.com/dyne/frei0r/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=bfe715df3d33c1acb857732962402bb8b0eef73e9dde1b58485d3e3b0e42e182
libs_dep=()

libs_args=(
    -DWITHOUT_OPENCV=ON
    -DWITHOUT_GAVL=ON
    -DWITHOUT_CAIRO=ON
)

libs_build() {
    # Disable opportunistic linking against Cairo
    sed -i CMakeLists.txt \
        -e 's/find_package (Cairo)//'

    cmake.setup

    cmake.build

    pkgfile libfrei0r -- cmake.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
