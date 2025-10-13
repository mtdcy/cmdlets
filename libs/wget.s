# Internet file retriever
#
# shellcheck disable=SC2034

upkg_lic='GPL-3.0-or-later'
upkg_ver=1.25.0
upkg_url=https://ftpmirror.gnu.org/gnu/wget/wget-$upkg_ver.tar.gz
upkg_sha=766e48423e79359ea31e41db9e5c289675947a7fcf2efdcedb726ac9d0da3784
upkg_dep=(zlib xz libidn2 openssl)

# using system tls on macOS
#is_darwin || upkg_dep+=(openssl)

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # default paths
    --sysconfdir=/etc

    --with-zlib
    --with-libidn
    --with-ssl=openssl

    # from homebrew:wget
    --disable-pcre
    --disable-pcre2
    --without-included-regex
    --without-libpsl

    #--enable-opie       # FTP opie
    #--enable-digest     # HTTP digest
    #--enable-ntlm       # NTLM

    --disable-nls
    --disable-rpath

    --disable-doc
    --disable-man

    --disable-shared
    --enable-static
)

upkg_static() {
    configure &&

    make &&

    # fast check
    ./src/wget -O /dev/null http://www.baidu.com &&

    # no top level check: https://git.alpinelinux.org/aports/tree/main/wget/APKBUILD
    #make -C tests check

    #make -C src install-exec &&
    cmdlet src/wget &&

    # verify
    check wget --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
