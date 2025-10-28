# Network authentication protocol

# shellcheck disable=SC2034
libs_lic=''
libs_ver=1.22.1
libs_url=https://kerberos.org/dist/krb5/1.22/krb5-1.22.1.tar.gz
libs_sha=1a8832b8cad923ebbf1394f67e2efcf41e3a49f460285a66e35adec8fa0053af
libs_dep=( openssl libedit )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --disable-nls
    --without-system-verto
    --without-keyutils

    --disable-shared
    --enable-static
)

libs_build() {
    # macOS has krb5
    depends_on is_linux

    cd src

    configure

    make

    pkgfile libkrb5 -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
