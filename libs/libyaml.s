# YAML parser

# shellcheck disable=SC2034
libs_name=libyaml
libs_lic="MIT"
libs_ver=0.2.5
libs_url=https://github.com/yaml/libyaml/archive/refs/tags/$libs_ver.tar.gz
libs_zip=$libs_name-$libs_ver.tar.gz
libs_sha=fa240dbf262be053f3898006d502d514936c818e422afdcf33921c63bed9bf2e

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-static
)

libs_build() {
    configure &&

    make &&

    library libyaml \
        include         include/yaml.h \
        lib             src/.libs/libyaml.a \
        lib/pkgconfig   yaml-0.1.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
