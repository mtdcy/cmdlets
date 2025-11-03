# User-space interfaces to POSIX 1003.1e capabilities

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=2.77
libs_url=https://mirrors.edge.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.77.tar.xz
libs_sha=897bc18b44afc26c70e78cead3dbb31e154acc24bee085a5a09079a88dbf6f52
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
    depends_on is_linux

    make "${libs_args[@]}"

    pkgfile libcap -- make -C libcap install "${libs_args[@]}"

    cmdlet ./progs/getcap
    cmdlet ./progs/setcap
    cmdlet ./progs/capsh
    cmdlet ./progs/getpcaps
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
