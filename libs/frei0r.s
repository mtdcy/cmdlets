# free video effect plugin collection

# shellcheck disable=SC2034
libs_lic="GPLv2"
libs_ver=2.5.2
libs_url=https://github.com/dyne/frei0r/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=fa6abb2a1e86cec4972f9dc891a4953c35d716a72b860c67888a26bbf1877862
libs_dep=()

libs_args=(
    -DWITHOUT_OPENCV=ON
    -DWITHOUT_GAVL=ON
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
