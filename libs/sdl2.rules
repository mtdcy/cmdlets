#
# shellcheck disable=SC2034
libs_lic="Zlib"
libs_ver=2.32.10
libs_rev=1
libs_url=https://github.com/libsdl-org/SDL/releases/download/release-$libs_ver/SDL2-$libs_ver.tar.gz
libs_sha=5f5993c530f084535c65a6879e9b26ad441169b3e25d789d83287040a9ca5165

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --without-x
    --enable-libiconv
    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    cmdlet.pkgfile libSDL2 -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
