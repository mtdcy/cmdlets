# Improved top (interactive process viewer)

libs_targets=( linux darwin )

# shellcheck disable=SC2034
libs_name=htop
libs_lic="GPL"
libs_ver=3.4.1
libs_url=https://github.com/htop-dev/htop/releases/download/$libs_ver/htop-$libs_ver.tar.xz
libs_sha=904f7d4580fc11cffc7e0f06895a4789e0c1c054435752c151e812fead9f6220

libs_deps=(ncurses) # enables mouse scroll

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --enable-dependency-tracking

    --enable-static
)

libs_build() {
    # wrong htop_git_version
    sed -i configure.ac \
        -e 's/\[git describe.*\]/[echo '']/'

    bootstrap

    configure 

    make 

    cmdlet.install htop

    cmdlet.check htop --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
