# free video effect plugin collection

# shellcheck disable=SC2034
libs_lic="GPL"
libs_ver=2.3.3
libs_url=https://github.com/dyne/frei0r/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=aeeefe3a9b44761b2cf110017d2b1dfa2ceeb873da96d283ba5157380c5d0ce5

libs_args=(
    -DWITHOUT_OPENCV=ON
    -DWITHOUT_GAVL=ON
)

libs_build() {
    mkdir -p build &&

    cd build &&

    cmake .. &&

    make &&

    library frei0r \
        include ../include/frei0r.h \
        lib/frei0r $(find . -name "*.so" | xargs) \
        lib/pkgconfig frei0r.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
