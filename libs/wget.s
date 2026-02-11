# Internet file retriever
#
# shellcheck disable=SC2034

libs_lic='GPL-3.0-or-later'
libs_ver=1.25.0
libs_url=https://ftpmirror.gnu.org/gnu/wget/wget-$libs_ver.tar.gz
libs_sha=766e48423e79359ea31e41db9e5c289675947a7fcf2efdcedb726ac9d0da3784

libs_deps=( zlib libiconv libunistring libidn2 libpsl openssl )
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # avoid hardcode PREFIX
    --sysconfdir=/etc
    --localedir=/no-locale

    --with-zlib
    --with-libidn
    --with-libpsl

    # ssl
    --with-ssl=openssl
    --with-libssl-prefix="'$PREFIX'"

    # unistring
    --with-libunistring-prefix="'$PREFIX'"
    --without-included-libunistring

    # included regex - easy the build
    --with-included-regex

    # included libraries
    #--enable-opie       # FTP opie
    #--enable-digest     # HTTP digest
    #--enable-ntlm       # NTLM

    --disable-nls
    --disable-doc
    --disable-man

    --disable-shared
    --enable-static
)

libs_build() {
    # wget configure did not handle static libraries well
    export LIBS="$($PKG_CONFIG --libs-only-l libcrypto)"

    configure

    make

    # fast check
    run src/wget -O /dev/null https://www.baidu.com || die "wget test failed."

    # no top level check: https://git.alpinelinux.org/aports/tree/main/wget/APKBUILD
    #make -C tests check

    #make -C src install-exec &&
    cmdlet.install src/wget

    # verify
    cmdlet.check wget --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
