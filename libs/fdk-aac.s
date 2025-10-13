
#
# shellcheck disable=SC2034
libs_lic="Apache-2.0"
libs_ver=2.0.3
libs_url=https://downloads.sourceforge.net/project/opencore-amr/fdk-aac/fdk-aac-$libs_ver.tar.gz
libs_sha=829b6b89eef382409cda6857fd82af84fabb63417b08ede9ea7a553f811cb79e

libs_args=(
    --disable-dependency-tracking
    --disable-example
    --disable-shared
    --enable-static
)

libs_build() {
    rm -fv CMakeLists.txt || true
    configure && make && make check &&

    library fdk-aac \
        include/fdk-aac libSYS/include/*.h libAACdec/include/*.h libAACenc/include/*.h \
        lib .libs/*.a \
        lib/pkgconfig fdk-aac.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
