# BSD-style licensed readline alternative

libs_targets=(! windows)

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=20260512-3.1
libs_url=https://thrysoee.dk/editline/libedit-$libs_ver.tar.gz
libs_sha=432d5e7ea8b0116dd39f2eca7bc11d0eed77faa6b77ea526ace89907c23ea4a0
libs_dep=(ncurses)

libs_args=(
    --enable-static --disable-shared
)

is_linux && libs_args+=(--with-privsep-path=/var/lib/sshd)

is_cygwin && libs_patches=(
    https://cygwin.com/cgit/cygwin-packages/libedit/plain/cygwin-build.patch
    https://cygwin.com/cgit/cygwin-packages/libedit/plain/libedit.patch
)

libs_build() {
    # historic: disclaim old libs_ver
    cmdlet.disclaim 3.1

    # libedit do not use pkg-config
    libs.requires ncurses

    configure

    make

    cmdlet.pkgfile libedit -- make install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
