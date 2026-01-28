# Cryptography and SSL/TLS Toolkit
#
# Headers Only:
#  we built shared libraries, but not suppose to use it.

# shellcheck disable=SC2034
libs_lic='Apache-2.0'
libs_ver=3.5.5
libs_url=https://www.openssl.org/source/openssl-$libs_ver.tar.gz
libs_sha=b28c91532a8b65a1f983b4c28b7488174e4a01008e29ce8e69bd789f28bc2a89
libs_dep=()

libs_args=(
    --prefix="$PREFIX"

    --libdir=lib

    # host paths
    --openssldir=/etc/ssl

    --api=3.0

    no-ssl3
    no-ssl3-method
    no-zlib

    no-shared

    # build legacy provider into libcrypto.a
    # https://github.com/openssl/openssl/issues/17679
    #  check provider with:
    #   default provider: openssl list -providers -verbose
    #   legacy provider: openssl list -providers -verbose -provider legacy
    no-module
)

is_linux  && libs_args+=( "linux-$(uname -m)" )

is_darwin && libs_args+=( "darwin64-$(uname -m)-cc" enable-ec_nistp_64_gcc_128 )

libs_build() {
    # -static will disable OPENSSL_THREADS
    export LDFLAGS="${LDFLAGS//-static /}"

    slogcmd ./Configure "${libs_args[@]}" || return 1

    make clean || true

    # ossl-modules: reset MODULESDIR
    make ENGINESDIR= MODULESDIR=

    pkgfile libopenssl -- make install_dev &&

    cmdlet ./apps/openssl openssl &&

    # verify
    check openssl version -a

    caveats << EOF
prebuilt static $(openssl version)

always search ca certs in /etc/ssl

provider:
    builtin default and legacy provider.

    OPENSSL_MODULES and -provider-path will not work.

env:
    OPENSSL_ENGINES : search engines in
EOF
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
