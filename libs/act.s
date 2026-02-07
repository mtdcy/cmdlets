# Run your GitHub Actions locally 🚀

# shellcheck disable=SC2034
libs_name=act
libs_lic="MIT"
libs_ver=0.2.84
libs_url=https://github.com/nektos/act/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=da58b74d03b2cd21df81aeb054c2792054d6cf9d4c3171e98440fde9becb01fa

libs_args=(
)

libs_build() {
    go.build && cmdlet act && check act
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
