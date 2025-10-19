# C library implementing the SSH2 protocol
#
# shellcheck disable=SC2034
libs_lic="BSD-3-Clause"
libs_ver=1.11.1
libs_url=https://github.com/libssh2/libssh2/releases/download/libssh2-$libs_ver/libssh2-$libs_ver.tar.gz
libs_sha=d9ec76cbe34db98eec3539fe2c899d26b0c837cb3eb466a56b0f109cabf658f7
libs_dep=( zlib openssl )

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --with-libz
    --with-openssl # no macos crypto support

    --disable-rpath
    --disable-examples-build

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    slogcmd ./buildconf

    configure

    make

    pkgfile libssh2 -- make install SUBDIRS=src
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
