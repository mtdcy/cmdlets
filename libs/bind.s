# Implementation of the DNS protocols

# shellcheck disable=SC2034
libs_lic='MPL-2.0'

# BIND releases with even minor version numbers (9.14.x, 9.16.x, etc) are stable.
libs_ver=9.21.0
libs_url=https://downloads.isc.org/isc/bind9/9.21.0/bind-9.21.0.tar.xz
libs_sha=b4c91c0e6767b62139e818e29b3bb4b9704bc14a868b25bf8491deea0254df96
libs_dep=( zlib libxml2 json-c libidn2 nghttp2 libuv openssl readline urcu jemalloc )

is_linux && libs_dep+=( libcap )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --sysconfdir=/etc
    --localstatedir=/var

    --with-json-c
    --with-libidn2
    --with-openssl="'$PREFIX'"
    --with-jemalloc

    --without-lmdb
    --without-cmocka

    --enable-developer  # need for build static
    --enable-static
    --disable-shared
)

libs_build() {

    # homebrew:
    # Apply macOS 15+ libxml2 deprecation to all macOS versions.
    # This allows our macOS 14-built Intel bottle to work on macOS 15+
    # and also cover the case where a user on macOS 14- updates to macOS 15+.
    is_darwin && CFLAGS+=" -DLIBXML_HAS_DEPRECATED_MEMORY_ALLOCATION_FUNCTIONS"

    CFLAGS+=" -Wno-error=implicit-function-declaration"

    export CFLAGS

    # static json-c
    export JSON_C_CFLAGS="$($PKG_CONFIG --cflags json-c)"
    export JSON_C_LIBS="$($PKG_CONFIG --libs json-c)"

    export LIBUV_CFLAGS="$($PKG_CONFIG --cflags libuv-static)"
    export LIBUV_LIBS="$($PKG_CONFIG --libs libuv-static)"

    configure

    # libisc has contructor and destructor in lib/isc/lib.c
    #  when build static libisc on macOS, the constructor
    #  and destructor won't be called.

    # hook isc constructor and destructor with a dummy function
    echo "void hook_isc__initialize(void);"     >> lib/isc/lib.c
    echo "void hook_isc__initialize(void) {}"   >> lib/isc/lib.c

    find bin/dig -name "*.c" -exec sed -i \
        -e '/^main(.*)\s\+{/a hook_isc__initialize();' \
        {} +

    # add this line before configure will cause gcc test fails, why?
    export LDFLAGS+=" -Wl,--undefined=hook_isc__initialize"

    pkgfile bind-libs -- make -C lib install

    # make all fails: build binaries only
    make -C bin/dig

    cmdlet ./bin/dig/dig
    cmdlet ./bin/dig/host
    cmdlet ./bin/dig/nslookup

    check dig www.google.com
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
