# Port of Sun's Transport-Independent RPC library to Linux

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.3.8
libs_rev=1
libs_url=https://downloads.sourceforge.net/project/libtirpc/libtirpc/1.3.8/libtirpc-1.3.8.tar.bz2
libs_sha=8839959bfcc7a0f4c609d8e4f53f1c67ae33de23775ec35beb39ff15adf11920

is_darwin || libs_dep=(krb5)

libs_resources=(
    https://github.com/libevent/libevent/raw/refs/heads/master/compat/sys/queue.h
)

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-shared
    --enable-static
)

libs_build() {
    is_darwin && export CFLAGS+=" -D__APPLE_USE_RFC_3542"

    # fix missing sys/queue.h for musl-gcc
    if is_musl; then
        mkdir -p compat/sys
        ln -sfv ../../queue.h compat/sys/
        export CPPFLAGS+=" -I$PWD/compat"
    fi

    configure

    make

    cmdlet.pkgfile $libs_name -- make install bin_SCRIPTS=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
