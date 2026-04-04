# Run your GitHub Actions locally 🚀

# shellcheck disable=SC2034
libs_name=act
libs_lic="MIT"
libs_ver=0.2.85
libs_url=https://github.com/nektos/act/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=bf4a7a71d98909c7d4ea604f16da5bb740559ba36955ea65ebe6b32951e7dce0

libs_args=(
)

libs_build() {
    go.build && cmdlet act && check act
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
