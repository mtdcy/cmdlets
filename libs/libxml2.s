# GNOME XML library

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=2.13.9
libs_url=https://download.gnome.org/sources/libxml2/2.13/libxml2-${libs_ver}.tar.xz
libs_sha=a2c9ae7b770da34860050c309f903221c67830c86e4a7e760692b803df95143a
libs_dep=(zlib libiconv readline)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --with-history # shell mode
    --without-http
    --without-lzma

    # python ?
    --without-python

    # icu4c ?
    --without-icu

    # https://gitlab.gnome.org/GNOME/libxml2/-/issues/751#note_2157870
    --with-legacy

    --disable-shared
    --enable-static
    )

libs_build() {

    configure &&

    make &&

    # 'Failed to open module' after update
#   {
#       # fixme: test fails in MSYS2
#       is_msys || make check V=1
#   } &&

    library libxml2                                      \
            include/libxml2/libxml  include/libxml/*.h   \
            lib                     .libs/*.a            \
            lib/cmake               libxml2-config.cmake \
            lib/pkgconfig           libxml-2.0.pc        \
            &&

    cmdlet  xmllint &&

    #inspect_install make install

    check xmllint --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
