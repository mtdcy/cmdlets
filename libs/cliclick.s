# Simple terminal UI for git commands

# shellcheck disable=SC2034
libs_lic=BSD-3-Clause
libs_ver=5.1
libs_url=https://github.com/BlueM/cliclick/archive/refs/tags/5.1.tar.gz
libs_sha=58bb36bca90fdb91b620290ba9cc0f885b80716cb7309b9ff4ad18edc96ce639

# configure args
libs_args=(
)

libs_build() {

    # Uses obsolete CGWindowListCreateImage and open PR doesn't work
    # Issue ref: https://github.com/BlueM/cliclick/issues/178
    export MACOSX_DEPLOYMENT_TARGET=14.0

    export OBJC="$CC"
    export OBJCFLAGS="$CFLAGS -include cliclick_Prefix.pch -I Actions -I ."

    make CC="'$CC'"

    cmdlet.install cliclick

    cmdlet.check cliclick
}

libs_depends is_darwin

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
