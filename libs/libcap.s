# User-space interfaces to POSIX 1003.1e capabilities

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=2.78
libs_url=https://mirrors.edge.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.78.tar.xz
libs_sha=0d621e562fd932ccf67b9660fb018e468a683d7b827541df27813228c996bb11
libs_dep=( )

libs_args=(
    prefix="'$PREFIX'"
    CC="'$CC'"
    CFLAGS="'$CFLAGS'"
    LDFLAGS="'$LDFLAGS'"
    lib=lib
    RAISE_SETFCAP=no

    # static only
    SHARED=no
)

# undefined reference to `__sprintf_chk'
#  musl does not provide __sprintf_chk without _FORTIFY_SOURCE
#   => undefine _FORTIFY_SOURCE
is_musl && libs_args+=(
    COPTS=

    LIBCSTATIC=yes
)

libs_build() {

    make "${libs_args[@]}"

    pkgfile libcap -- make -C libcap install "${libs_args[@]}"

    cmdlet ./progs/getcap
    cmdlet ./progs/setcap
    cmdlet ./progs/capsh
    cmdlet ./progs/getpcaps
}

libs.depends is_linux

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
