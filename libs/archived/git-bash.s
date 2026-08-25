# Git + bash for windows (prebuilt)

libs_targets=( windows )

# shellcheck disable=SC2034
libs_lic=GPLv2
libs_ver=2.53.0
libs_url=https://github.com/git-for-windows/git/releases/download/v2.53.0.windows.1/Git-2.53.0-64-bit.tar.bz2
libs_sha=d0a44fba2cc47e053ed987584d8392675c12a1465690ad1a36f09743a2ffe15e

#libs_url=https://github.com/git-for-windows/git/archive/refs/tags/v2.53.0.windows.1.tar.gz
#libs_sha=e7cbff8d1f3377bd6bd1f927bad56d70c4893395baddd4639ed30d5e902d9d01

libs_deps=( )

libs_args=(
)

libs_build() {
    cmdlet.pkginst bash bin \
        bin/bash.exe \
        usr/bin/msys-2.0.dll
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
