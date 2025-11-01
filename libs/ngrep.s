# ngrep is like GNU grep applied to the network layer.

# shellcheck disable=SC2034
libs_lic='BSD'
libs_ver=1.48.0
libs_url=https://github.com/jpr5/ngrep/archive/refs/tags/v1.48.0.tar.gz
libs_sha=49a20b83f6e3d9191c0b5533c0875fcde83df43347938c4c6fa43702bdbd06b4
libs_dep=( libpcap pcre2 )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --enable-ipv6
    --enable-pcre2
)

libs_build() {
    # no pcre2-config
    hack.pcre2 configure

    configure

    make.all

    cmdlet.install  ngrep

    cmdlet.check    ngrep
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
