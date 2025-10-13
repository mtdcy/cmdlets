
#
# shellcheck disable=SC2034
libs_lic="LGPL-2.1-or-later"
libs_ver=0.1.3
libs_url=https://downloads.sourceforge.net/project/soxr/soxr-$libs_ver-Source.tar.xz
libs_sha=b111c15fdc8c029989330ff559184198c161100a59312f5dc19ddeb9b5a15889

libs_args=(
    -DWITH_OPENMP=OFF
    -DBUILD_SHARED_LIBS=OFF
    -DWITH_LSR_BINDINGS=OFF
    -DBUILD_TESTS=OFF
    -DBUILD_EXAMPLES=OFF
)

libs_build() {
    cmake . &&

    make &&

    library soxr \
            include         src/soxr.h \
            lib             src/libsoxr.a \
            lib/pkgconfig   src/soxr.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
