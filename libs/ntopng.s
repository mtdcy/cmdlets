# Next generation version of the original ntop

# shellcheck disable=SC2034
libs_lic='GPLv3'
libs_ver=6.4
libs_url=https://github.com/ntop/ntopng/archive/refs/tags/6.4.tar.gz
libs_sha=3eaff9f13566e349cada66d41191824a80288ea19ff4427a49a682386348931d
libs_dep=( zlib zstd libpcap curl expat hiredis json-c libmaxminddb libsodium ndpi openssl sqlite zeromq rrdtool lua )
# mariadb-connector-c

is_linux && libs_dep+=( libcap )

libs_patches=(
    # Add `--with-dynamic-ndpi` configure flag, Remove in the next release
    https://github.com/ntop/ntopng/commit/a195be91f7685fcc627e9ec88031bcfa00993750.patch?full_index=1
    # Fix compilation error when using `--with-synamic-ndpi` flag
    # https://github.com/ntop/ntopng/pull/9252
    https://github.com/ntop/ntopng/commit/0fc226046696bb6cc2d95319e97fad6cb3ab49e1.patch?full_index=1
)

libs_args=(
    # runtime paths
    --localstatedir=/tmp # where

    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --with-zmq-static
    --with-json-c-static
    --with-maxminddb-static

    --with-ndpi-static-lib="'$PREFIX/lib'"
    --with-ndpi-includes="'$PREFIX/include/ndpi'"

    --disable-shared
    --enable-static
)

libs_build() {
    # remove included libraries
    rm -rf third-party/json-c*
    rm -rf third-party/rrdtool*
    rm -rf third-party/lua-*

    # fix static libcurl
    export LIBS="$($PREFIX/bin/curl-config --static-libs)"

    slogcmd ./autogen.sh

    configure

    # ntop configure do not handle CC/CXX env
    hack.makefile Makefile CC CXX

    # force use installed lua
    sed -i Makefile \
        -e '/[[:blank:]]*LUA_LIB=/d' \
        -e '/[[:blank:]]*LUA_INC=/d' \
        -e '/^\$(LUA_LIB):/,+1 d' \
        -e '/LIB_TARGETS/s/\$(LUA_LIB)//'
    export LUA_LIB="$($PKG_CONFIG --libs-only-l lua)"
    export LUA_INC="$($PKG_CONFIG --cflags-only-I lua)"

    make.all

    cmdlet.install ntopng

    # install resources
    mkdir -p $PREFIX/share/ntopng
    cp -r ./httpdocs $PREFIX/share/ntopng
	cp -LR ./scripts $PREFIX/share/ntopng # L dereference symlinks

    pkgfile httpdocs share/ntopng/httpdocs
    pkgfile scripts  share/ntopng/scripts

    cmdlet.check ntopng --version

    cmdlet.caveats << EOF
static build $libs_name @ $libs_ver

Quick Start:
    cmdlets.sh install ntopng/httpdocs
    cmdlets.sh install ntopng/scripts
    cmdlets.sh install ntopng

    cmdlets.sh link share/ntopng ~/.ntopng

    # setup redis

    ntopng --httpdocs-dir  ~/.ntopng/httpdocs           \\
           --scripts-dir   ~/.ntopng/scripts            \\
           --callbacks-dir ~/.ntopng/scripts/callbacks
EOF
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
