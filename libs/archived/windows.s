# MinGW-w64 headers for Windows (mingw-w64)
#
# 经典 Win32 SDK / 传统 COM (Classic COM)
# C 语言 与 传统 C++ 均可使用

libs_targets=(windows)
libs_stable=1

# shellcheck disable=SC2034
libs_lic="ZPLv2.1 & LGPLv2.1+"
libs_ver=14.0.0
libs_url=https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-headers-14.0.0.r302.gd7f3c5201-1-any.pkg.tar.zst
libs_sha=5ef6b34cea46b8c7416077f116d5a20828125a7f189b9ee315202a4a8b1cae2b

# configure args
libs_build() {

    cmdlet.pkginst libwin32-headers                             \
        include                 mingw64/include/*               \
        include/gdiplus         mingw64/include/gdiplus/*       \
        include/psdk_inc        mingw64/include/psdk_inc/*      \
        include/sec_api         mingw64/include/sec_api/*       \
        include/sec_api/sys     mingw64/include/sec_api/sys/*   \
        include/wrl             mingw64/include/wrl/*           \
        include/wrl/wrappers    mingw64/include/wrl/wrappers/*  \
        include/ddk             mingw64/include/ddk/*           \
        include/KHR             mingw64/include/KHR/*           \
        include/sys             mingw64/include/sys/*           \
        include/GL              mingw64/include/GL/*            \

}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
