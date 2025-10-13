# Improved top (interactive process viewer)

# shellcheck disable=SC2034
libs_name=htop
libs_lic="GPL"
libs_ver=3.4.1
libs_url=https://github.com/htop-dev/htop/releases/download/$libs_ver/htop-$libs_ver.tar.xz
libs_sha=904f7d4580fc11cffc7e0f06895a4789e0c1c054435752c151e812fead9f6220
libs_dep=(ncurses) # enables mouse scroll

libs_build() {
    ./autogen.sh &&

    configure &&

    make &&

    make install &&

    cmdlet htop &&

    check htop
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
