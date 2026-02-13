# regex functionality from glibc 2.22 extracted for Win32.

# shellcheck disable=SC2034
libs_lic=LGPLv2.1
libs_ver=2.6.1
libs_url=https://github.com/TimothyGu/libgnurx/releases/download/libgnurx-2.6.1/mingw-libgnurx-2.6.1-src.tar.gz
libs_sha=ee6edc110c6b63d0469f4f05ef187564b310cc8a88b6566310a4aebd48b612c7

libs_deps=()

libs_args=(
    --disable-option-checking
)

libs_build() {
    configure 

    make regex.o

    cmdlet.archive libgnurx.a regex.o

    cmdlet.pkgconf libgnurx.pc -lregex 

    # libgnurx do not honor DESTDIR, use pkginst instead
    pkginst libgnurx regex.h libgnurx.a libgnurx.pc
}

libs.depends is_mingw

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
