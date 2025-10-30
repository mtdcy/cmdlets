# aria2 is a lightweight multi-protocol & multi-source command-line download utility.

# shellcheck disable=SC2034
libs_lic='GPL-2.0+'
libs_ver=1.37
libs_url=https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0.tar.xz
libs_sha=60a420ad7085eb616cb6e2bdf0a7206d68ff3d37fb5a956dc44242eb2f79b66b
libs_dep=( zlib libxml2 libssh2 sqlite )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    # enable features explicitly
    --enable-bittorrent
    --enable-metalink

    --with-libssh2  # sftp
    --with-libxml2  # Metalink
    --with-sqlite3  # Firefox/Chrome cookie

    # If OpenSSL is selected over GnuTLS,
    # neither libnettle nor libgcrypt will be used.
    --without-gnutls
    --without-libgmp
    --without-libnettle
    --without-libgcrypt

    # no nls and rpath for static build
    --disable-rpath
    --disable-nls
    --without-libintl-prefix

    --disable-shared
    --enable-static
)

# openssl
if is_darwin; then
    libs_args+=(
        --with-appletls
        --without-openssl
    )
else
    libs_dep+=( openssl )
    libs_args+=(
        --without-appletls
        --with-openssl
    )
fi

libs_build() {
    configure

    make

    cmdlet ./src/aria2c

    check aria2c -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
