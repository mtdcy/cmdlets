# GNU implementation of which utility

# shellcheck disable=SC2034
libs_lic=GPLv3+
libs_ver=2.25
libs_rev=1
libs_url=${LIBS_MIRROR_GNU:-https://ftpmirror.gnu.org/gnu}/which/which-2.25.tar.gz
libs_sha=1cb83e4f702e60b8211ab5ec4c2afbab1b1dec80209456a7d2faf7584ed225ea
libs_deps=()

libs_args=(
    # static only
    --enable-static --disable-shared
)

is_cygwin && libs_resources=(
    https://cygwin.com/cgit/cygwin-packages/which/plain/cygwin.patch
)

libs_build() {
    if is_cygwin; then
        slogcmd patch -Nbp2 -i cygwin.patch
    fi

    # fix error: conflicting types for 'getopt'
    libs.requires -std=gnu99

    configure

    make

    cmdlet.install ./which

    cmdlet.check which --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
