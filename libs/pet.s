# Simple command-line snippet manager

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=1.0.1
libs_url=https://github.com/knqyf263/pet/archive/refs/tags/v1.0.1.tar.gz
libs_sha=b829628445b8a7039f0211fd74decee41ee5eb1c28417a4c8d8fca99de59091f

libs_args=(
)

libs_build() {
    go.setup

    go.build

    cmdlet.install "$libs_name"

    cmdlet.check "$libs_name" --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
