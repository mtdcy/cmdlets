#
libs_ver=0.11.0

_suffix=v$libs_ver

is_darwin && _suffix+=".darwin" || _suffix+=".linux"
is_arm64 && _suffix+=".aarch64" || _suffix+=".x86_64"

libs_url=https://github.com/koalaman/shellcheck/releases/download/v$libs_ver/shellcheck-$_suffix.tar.xz


libs_build() {
    cmdlet $(find . -name shellcheck) &&

    check shellcheck --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
