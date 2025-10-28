# User-space interfaces to POSIX 1003.1e capabilities

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=2.76
libs_url=https://mirrors.edge.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.76.tar.xz
libs_sha=629da4ab29900d0f7fcc36227073743119925fd711c99a1689bbf5c9b40c8e6f
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
is_musl_gcc && libs_args+=(
    COPTS=

    LIBCSTATIC=yes
)

libs_build() {
    depends_on is_linux

    make "${libs_args[@]}"

    pkgfile libcap -- make -C libcap install "${libs_args[@]}"

    cmdlet ./progs/getcap
    cmdlet ./progs/setcap
    cmdlet ./progs/capsh
    cmdlet ./progs/getpcaps
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
