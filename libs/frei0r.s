# free video effect plugin collection

# shellcheck disable=SC2034
libs_lic="GPLv2"
libs_ver=2.5.4
libs_url=https://github.com/dyne/frei0r/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=e5536fe659682a3d0e7d98b759174ad8bf3e79bdda78d919d503d8c3d7fd35a0
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
