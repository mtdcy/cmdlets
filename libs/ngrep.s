# ngrep is like GNU grep applied to the network layer.

# shellcheck disable=SC2034
libs_lic='BSD'
libs_ver=1.49.0
libs_url=https://github.com/jpr5/ngrep/archive/refs/tags/v1.49.0.tar.gz
libs_sha=6c94b31681316b7469a3ace92d2aeec7c9f490bd6782453dff2ade0e289a3348
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
