# Port of Sun's Transport-Independent RPC library to Linux

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.3.7
libs_url=https://downloads.sourceforge.net/project/libtirpc/libtirpc/1.3.7/libtirpc-1.3.7.tar.bz2
libs_sha=b47d3ac19d3549e54a05d0019a6c400674da716123858cfdb6d3bdd70a66c702

is_darwin || libs_dep=( krb5 )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-shared
    --enable-static
)

libs_build() {
    is_darwin && export CFLAGS+=" -D__APPLE_USE_RFC_3542"

    # no krb5-config
    export KRB5_CONFIG="$PKG_CONFIG"

    configure

    make

    pkgfile $libs_name -- make install bin_SCRIPTS=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
