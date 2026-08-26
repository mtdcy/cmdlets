# a static analysis tool for shell scripts

libs_targets=(! windows) # no prebuilts for windows

# shellcheck disable=SC2034
libs_ver=0.11.0
libs_lic=GPLv3

_suffix=v$libs_ver

is_darwin && _suffix+=".darwin" || _suffix+=".linux"
is_arm64 && _suffix+=".aarch64" || _suffix+=".x86_64"

libs_url=https://github.com/koalaman/shellcheck/releases/download/v$libs_ver/shellcheck-$_suffix.tar.xz

libs_build() {
    cmdlet.install $(find . -name shellcheck)

    cmdlet.check shellcheck --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
