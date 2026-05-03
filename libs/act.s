# Run your GitHub Actions locally 🚀

# shellcheck disable=SC2034
libs_name=act
libs_lic="MIT"
libs_ver=0.2.88
libs_url=https://github.com/nektos/act/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=a70c187ee403b53ead14b53296671528787734980b99d6deba029191c69ab131

libs_args=(
)

libs_build() {
    go.build && cmdlet act && check act
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
