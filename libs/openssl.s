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

# https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-openssl/PKGBUILD
if is_mingw; then
    libs_args+=( mingw64 )

    libs_patches=(
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-openssl/002-relocation.patch
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-openssl/004-arch-suffix.patch
    )

    libs_resources=(
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-openssl/pathtools.c
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-openssl/pathtools.h

        # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=mingw-w64-openssl
        # clear bad commit: https://github.com/openssl/openssl/commit/4a7d9705f30842b402058324a6947938fe3486ec.patch
        https://github.com/openssl/openssl/commit/4a7d9705f30842b402058324a6947938fe3486ec.patch
    )
fi

libs_build() {
    # -static will disable OPENSSL_THREADS
    export LDFLAGS="${LDFLAGS//-static /}"

    # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-openssl/PKGBUILD
    if is_mingw; then
        cp pathtools.c crypto/

        # Use mingw cflags instead of hardcoded ones
        sed -i Configurations/10-main.conf \
            -e '/^"mingw"/ s/-fomit-frame-pointer -O3 -Wall/-O2 -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions --param=ssp-buffer-size=4/'

        slogcmd patch --reverse -p1 -i 4a7d9705f30842b402058324a6947938fe3486ec.patch
    fi

    slogcmd ./Configure "${libs_args[@]}" || return 1

    # ossl-modules: reset MODULESDIR
    make ENGINESDIR= MODULESDIR=

    # simple tests/ssl
    echo | run apps/openssl s_client -connect google.com:443 | grep -q "Verification: OK" || die "openssl connect failed"

    # crypto: common used ciphers
    local txt="This is a secret message"
    for cipher in aes-256-cbc aes-256-cfb chacha20; do
        echo "$txt" | run apps/openssl enc -$cipher -a -salt -pass pass:passwd > encrypted.txt 
        local decrypted="$(cat encrypted.txt | run apps/openssl enc -$cipher -a -d -salt -pass pass:passwd 2>/dev/null)"
        [ "$decrypted" = "$txt" ] || die "openssl cipher $cipher failed: |$decrypted|"
    done

    pkgfile libopenssl -- make install_dev

    cmdlet.install apps/openssl
    cmdlet.install tools/c_rehash

    # verify
    cmdlet.check openssl version -a

    cmdlet.caveats << EOF
prebuilt static openssl @ $libs_ver

$(run apps/openssl version -a)

$(run apps/openssl list -providers)

    OR set env OPENSSL_MODULES instead

$(run apps/openssl list -engines)

    OR set env OPENSSL_ENGINES instead
EOF
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
