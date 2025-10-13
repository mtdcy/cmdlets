# Interpreter for the AWK Programming Language

# shellcheck disable=SC2034
libs_lic='GPL-2.0'
libs_ver=1.3.4
libs_url=https://invisible-mirror.net/archives/mawk/mawk-$libs_ver-20250131.tgz
libs_sha=51bcb82d577b141d896d9d9c3077d7aaa209490132e9f2b9573ba8511b3835be
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # better for static binary
    --enable-builtin-srand
    # ubuntu use this
    --enable-arc4random
)

libs_build() {
    configure && 

    make mawk &&

    cmdlet ./mawk && 

    check mawk --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
