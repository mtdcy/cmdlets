# Port scanning utility for large networks

# shellcheck disable=SC2034
libs_ver=7.98
libs_url=https://nmap.org/dist/nmap-7.98.tar.bz2
libs_sha=ce847313eaae9e5c9f21708e42d2ab7b56c7e0eb8803729a3092f58886d897e6
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
