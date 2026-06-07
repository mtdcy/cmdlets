# Run your GitHub Actions locally 🚀

# shellcheck disable=SC2034
libs_name=act
libs_lic="MIT"
libs_ver=0.2.89
libs_url=https://github.com/nektos/act/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=649cd5b91cad870871d2283fb3ad95c8fa1d5ced7a1db8d7b346d1a7dcd3ec71

libs_args=(
)

libs_build() {
    go.build && cmdlet act && check act
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
