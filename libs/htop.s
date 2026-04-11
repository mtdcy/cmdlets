# Improved top (interactive process viewer)

libs_targets=( linux darwin )

# shellcheck disable=SC2034
libs_name=htop
libs_lic="GPL"
libs_ver=3.5.0
libs_url=https://github.com/htop-dev/htop/releases/download/$libs_ver/htop-$libs_ver.tar.xz
libs_sha=b6586e405c5223ebe5ac7828df21edad45cbf90288088bd1b18ad8fa700ffa05

libs_deps=(ncurses) # enables mouse scroll

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --enable-dependency-tracking

    --enable-static
)

libs_build() {
    #1. wrong htop_git_version
    sed -i configure.ac \
        -e 's/\[git describe.*\]/[echo '']/'

    #2. no -static LDFLAGS for darwin
    #   => BUILD_STATIC is enough for darwin
    is_darwin && sed -i '/FLAGS -static/d' configure.ac

    bootstrap

    configure

    make

    cmdlet.install htop

    cmdlet.check htop --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
