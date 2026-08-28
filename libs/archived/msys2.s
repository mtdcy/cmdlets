# msys2 development files

libs_targets=( windows )

# shellcheck disable=SC2034
libs_lic=GPL
libs_ver=3.6.6
libs_url=https://mirror.msys2.org/msys/x86_64/msys2-runtime-devel-3.6.6-1-x86_64.pkg.tar.zst
libs_sha=c3ce00a4d098cf67be4098b891f1f18ae791ac4e972d9248455a262147ec4d3f

libs_deps=( )

libs_args=( )

libs_build() {
    # mingw32-w64 also uses __CYGWIN__
    # __CYGWIN__ => __MSYS2__CYGWIN__
    grep -Rwl __CYGWIN__ . | xargs sed -i 's/\<__CYGWIN__\>/__MSYS2__CYGWIN__/g'

    # do not install to include or lib directories
    cmdlet.pkginst msys2 share/msys2 usr/include usr/lib
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
