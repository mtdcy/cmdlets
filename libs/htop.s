# Improved top (interactive process viewer)

libs_targets=( linux darwin )

# shellcheck disable=SC2034
libs_name=htop
libs_lic="GPL"
libs_ver=3.5.1
libs_url=https://github.com/htop-dev/htop/releases/download/$libs_ver/htop-$libs_ver.tar.xz
libs_sha=526cecd62870aa8d14d2a79a35ea197e4e2b5317d275b567cee0574b2ddb2e9a

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
