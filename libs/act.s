# Run your GitHub Actions locally 🚀

# shellcheck disable=SC2034
libs_name=act
libs_lic="MIT"
libs_ver=0.2.86
libs_url=https://github.com/nektos/act/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=5717a45d967ddbb5e227b4029dfde4d7757477ec2d828486f714f75695f05c86

libs_args=(
)

libs_build() {
    go.build && cmdlet act && check act
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
