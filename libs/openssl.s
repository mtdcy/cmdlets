# Cryptography and SSL/TLS Toolkit
#
# Headers Only:
#  we built shared libraries, but not suppose to use it.

# shellcheck disable=SC2034
libs_lic='Apache-2.0'
libs_ver=3.6.1
libs_url=https://github.com/openssl/openssl/releases/download/openssl-3.6.1/openssl-3.6.1.tar.gz
libs_sha=b1bfedcd5b289ff22aee87c9d600f515767ebf45f77168cb6d64f231f518a82e
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

    pkgfile libopenssl -- make install_dev

    cmdlet.install apps/openssl
    cmdlet.install tools/c_rehash

    # verify
    cmdlet.check openssl version -a

    cmdlet.caveats << EOF
prebuilt static openssl @ $libs_ver

$(./apps/openssl version -a)

$(./apps/openssl list -providers)

    OR set env OPENSSL_MODULES instead

$(./apps/openssl list -engines)

    OR set env OPENSSL_ENGINES instead
EOF
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
