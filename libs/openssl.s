# Cryptography and SSL/TLS Toolkit
#
# Headers Only:
#  we built shared libraries, but not suppose to use it.

# shellcheck disable=SC2034
libs_lic='Apache-2.0'
libs_ver=3.5.4
libs_url=https://www.openssl.org/source/openssl-$libs_ver.tar.gz
libs_sha=967311f84955316969bdb1d8d4b983718ef42338639c621ec4c34fddef355e99
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
)

is_linux  && libs_args+=( "linux-$(uname -m)" )

is_darwin && libs_args+=( "darwin64-$(uname -m)-cc" enable-ec_nistp_64_gcc_128 )

libs_build() {
    # -static will disable OPENSSL_THREADS
    export LDFLAGS="${LDFLAGS//-static /}"

    slogcmd ./Configure "${libs_args[@]}" || return 1

    make clean || true

    # ossl-modules: set OPENSSL_MODULES env instead
    make ENGINESDIR= MODULESDIR=

    pkgfile libopenssl -- make install_dev &&

    cmdlet ./apps/openssl openssl &&

    # verify
    check openssl version -a

    caveats << EOF
prebuilt static $(openssl version)

always search ca certs in /etc/ssl

env:
    OPENSSL_MODULES : search modules in
    OPENSSL_ENGINES : search engines in
EOF
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
