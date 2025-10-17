#
# shellcheck disable=SC2034
libs_lic="Zlib"
libs_ver=2.30.12
libs_url=https://github.com/libsdl-org/SDL/releases/download/release-$libs_ver/SDL2-$libs_ver.tar.gz
libs_sha=ac356ea55e8b9dd0b2d1fa27da40ef7e238267ccf9324704850d5d47375b48ea

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --without-x
    --enable-libiconv
    --disable-shared
    --enable-static
)

libs_build() {
    configure && make || return $?

    pkgfile libSDL2 -- make install INSTALL_SDL2_CONFIG=FALSE &&

    cmdlet sdl2-config
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
