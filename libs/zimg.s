# Scaling, colorspace conversion, and dithering library
#
# shellcheck disable=SC2034

libs_lic="WTFPL"
libs_ver=3.0.6
libs_url=https://github.com/sekrit-twc/zimg/archive/refs/tags/release-$libs_ver.tar.gz
libs_sha=be89390f13a5c9b2388ce0f44a5e89364a20c1c57ce46d382b1fcc3967057577
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-example
    --enable-testapp

    --disable-shared
    --enable-static
)

libs_build() {
    configure && make || return $?

    {
        if is_linux; then
            sed -i 's/^Libs.private:.*$/& -lm/' zimg.pc
        fi
    }

    pkgfile libzimg -- make install dist_example_DATA= dist_examplemisc_DATA=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
