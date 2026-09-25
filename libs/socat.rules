# SOcket CAT: netcat on steroids

# shellcheck disable=SC2034
libs_targets=( ! windows )

libs_lic="GPLv2"
libs_ver=1.8.1.1
libs_url=(
    https://distfiles.alpinelinux.org/distfiles/edge/socat-1.8.1.1.tar.gz
    http://www.dest-unreach.org/socat/download/socat-1.8.1.1.tar.gz
)
libs_sha=f68b602c80e94b4b7498d74ec408785536fe33534b39467977a82ab2f7f01ddb

libs_deps=( )

# configure args
libs_args=(
    --disable-option-checking

    # build minimal socat
    --disable-tun
    --disable-openssl
    --disable-readline

    --disable-shared
    --enable-static
)

libs_build() {
    configure 

    make

    cmdlet.install socat
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
