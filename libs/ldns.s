# DNS library written in C

libs_stable=1

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.8.3
libs_url=(
    https://github.com/NLnetLabs/ldns/archive/refs/tags/1.8.3.tar.gz
    https://nlnetlabs.nl/downloads/ldns/ldns-1.8.3.tar.gz
)
libs_sha=33fb1a77f2de2fca9e749d17256334a3222a9e9d11b31c6d998bd920f3bd6776
libs_dep=( openssl )

# https://github.com/msys2/MINGW-packages/tree/master/mingw-w64-ldns
if is_mingw; then
    libs_patches=(
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-ldns/001-include-missing-header-ws2tcpip.patch
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-ldns/ldns-1.6.17-relocate.patch
    )
    libs_resources=(
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-ldns/pathtools.c
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-ldns/pathtools.h
    )
fi

libs_args=(
    --with-ssl="'$PREFIX'" # DNSSEC

    --with-drill

    --disable-dane-verify
    --without-xcode-sdk

    --without-pyldns
    --without-examples

    --disable-shared
    --enable-static
)

libs_build() {
    # fix libldns.pc
    #export LDFLAGS+=" $($PKG_CONFIG --libs openssl)"

    # configure: ldns won't check libraries type and just do -lcrypto
    export LIBS="$($PKG_CONFIG --libs-only-l libcrypto)"

    # sh: 0: cannot open ./install-sh: No such file, WHY?
    ln -sfv drill/install-sh ./

    configure

    make

    pkgfile libldns -- make install-h install-lib install-pc

}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
