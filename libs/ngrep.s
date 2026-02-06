# ngrep is like GNU grep applied to the network layer.

# shellcheck disable=SC2034
libs_lic='BSD'
libs_ver=1.48.3
libs_url=https://github.com/jpr5/ngrep/archive/refs/tags/v1.48.3.tar.gz
libs_sha=7c69777c21cc491368b2f1fe057d1d44febcf42413a885b59badeade5264a066
libs_dep=( libpcap pcre2 )

libs_args=(
    --enable-ipv6
    --enable-pcre2
)

libs_build() {
    configure

    make.all

    cmdlet.install  ngrep

    cmdlet.check    ngrep
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
