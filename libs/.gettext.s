# An internationalization and localization (i18n and l10n) system commonly used for writing multilingual programs.

# shellcheck disable=SC2034
libs_lic='GPL'
libs_ver=0.23
libs_url=https://ftpmirror.gnu.org/gnu/gettext/gettext-${libs_ver}.tar.gz
libs_sha=945dd7002a02dd7108ad0510602e13416b41d327898cf8522201bc6af10907a6
libs_dep=(libunistring libxml2 ncurses libiconv)

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --enable-silent-rules

    --without-included-libunistring
    --without-included-libxml

    --disable-examples
    --disable-java
    --disable-csharp

    --disable-nls
    --disable-rpath

    # static only
    --disable-shared
    --enable-static

    # Don't use VCS systems to create these archives
    --without-git
    --without-cvs
    --without-xz
)

# libintl.h for macOS only, Linux use glibc:/usr/include/libintl.h
is_linux || libs_args+=(--with-included-gettext)

libs_build() {
    # install doesn't support multiple make jobs
    configure &&

    make &&

    TERM=xterm make check install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
