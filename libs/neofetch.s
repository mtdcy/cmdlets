# A command-line system information tool written in bash 3.2+
#
# shellcheck disable=SC2034

libs_lic="MIT"
libs_ver=7.1.0
libs_url=https://github.com/dylanaraps/neofetch/archive/refs/tags/$libs_ver.tar.gz
libs_zip=neofetch-$libs_ver.tar.gz
libs_sha=58a95e6b714e41efc804eca389a223309169b2def35e57fa934482a6b47c27e7

libs_build() {
    make all install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
