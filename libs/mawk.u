# Interpreter for the AWK Programming Language

# shellcheck disable=SC2034
upkg_lic='GPL-2.0'
upkg_ver=1.3.4
upkg_url=https://invisible-mirror.net/archives/mawk/mawk-$upkg_ver-20250131.tgz
upkg_sha=51bcb82d577b141d896d9d9c3077d7aaa209490132e9f2b9573ba8511b3835be
upkg_dep=()

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # better for static binary
    --enable-builtin-srand
    # ubuntu use this
    --enable-arc4random
)

upkg_static() {
    configure && 

    make mawk &&

    cmdlet ./mawk && 

    check mawk --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
