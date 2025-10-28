# TCP connect to the given IP/port combo

# shellcheck disable=SC2034
libs_lic='MIT'
libs_ver=2.1.0
libs_url=https://github.com/mkirchner/tcping/archive/refs/tags/2.1.0.tar.gz
libs_sha=b8aa427420fe00173b5a2c0013d78e52b010350f5438bf5903c1942cba7c39c9
libs_dep=( )

libs_args=(
)

libs_build() {

    make CC="'$CC'" CCFLAGS="'$CCFLAGS $CPPFLAGS $LDFLAGS'"

    cmdlet ./tcping

    check tcping
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
