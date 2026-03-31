# Port scanning utility for large networks

# shellcheck disable=SC2034
libs_ver=7.99
libs_url=https://nmap.org/dist/nmap-7.99.tar.bz2
libs_sha=df512492ffd108e53a27a06f26d8635bbe89e0e569455dc8ffef058c035d51b2
libs_dep=( zlib libpcap liblinear libssh2 openssl pcre2 )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --with-liblua=included
    --with-libpcre="'$PREFIX'"
    --with-openssl="'$PREFIX'"
    --with-libpcap="'$PREFIX'"
    --with-libssh2="'$PREFIX'"
    --with-libz="'$PREFIX'"

    --disable-universal
    --without-nmap-update
    --without-zenmap
    --without-ndiff

    --disable-debug
    --disable-doxygen-doc

    --disable-shared
    --enable-static
)

libs_build() {
    deparallelize

    # Fix to missing VERSION file
    # https://github.com/nmap/nmap/pull/3111
    mv -f libpcap/VERSION.txt libpcap/VERSION

    configure

    make nmap
    cmdlet ./nmap

    make -C nping
    cmdlet ./nping/nping nmap-ping

    make -C ncat
    cmdlet ./ncat/ncat nmap-cat

    check nmap --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
