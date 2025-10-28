# DNS library written in C

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.8.4
libs_url=(
    https://github.com/NLnetLabs/ldns/archive/refs/tags/1.8.4.tar.gz
    https://nlnetlabs.nl/downloads/ldns/ldns-1.8.4.tar.gz
)
libs_sha=b64a0f619ecb74aaf5fe4fbbb4640b150aec55f9a708031a68b3b4fae95326a2
libs_dep=( openssl )

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
    export LDFLAGS+=" $($PKG_CONFIG --libs openssl)"

    # sh: 0: cannot open ./install-sh: No such file, WHY?
    ln -sfv drill/install-sh ./

    configure

    make

    pkgfile libldns -- make install-h install-lib install-pc

}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
