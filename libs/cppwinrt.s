# C++ language projection for Windows Runtime (WinRT) APIs (mingw-w64)

libs_targets=( windows )

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=2.0.250303.1
libs_url=https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-cppwinrt-2.0.250303.1-1-any.pkg.tar.zst
libs_sha=bf68d4f4bb1cb03bc398a05cd70cf92a92315d3e96e83c65aa1dc213d1f90189

# configure args
libs_build() {
    # Windows and mingw headers are case insensitive
    #  => but our build system runs on Linux which is case sensitive
    #   => rename all files to lower case
    while read -r x; do
        x="${x#mingw64/}"
        mkdir -p "${x%/*}"
        cp "mingw64/$x" "$(echo "$x" | tr A-Z a-z)" || true
        sed -i '/include .*Windows\..*\.h/s/.*/\L&/' "$x"
    done < <(find mingw64/include -name "*.h")

    # -std=c++20    : error: C++/WinRT requires coroutine support
    # -fpermissive  : error: invalid conversion
    pkgconf libwinrt.pc -std=c++20 -fpermissive

    cmdlet.pkginst libwinrt                        \
        include/winrt       include/winrt/*.h      \
        include/winrt/impl  include/winrt/impl/*.h \
        libwinrt.pc

    cmdlet.install mingw64/bin/cppwinrt.exe

    cmdlet.check cppwinrt.exe
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
