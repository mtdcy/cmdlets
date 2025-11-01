# Top-like interface for container metrics

# shellcheck disable=SC2034
libs_lic="MIT"
libs_ver=0.7.7
libs_url=https://github.com/bcicen/ctop/archive/refs/tags/v0.7.7.tar.gz
libs_sha=0db439f2030af73ad5345884b08a33a762c3b41b30604223dd0ebddde72d2741

libs_args=(
)

libs_build() {
    go.setup

    go.build -tags release -o "$libs_name"

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" -v
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
