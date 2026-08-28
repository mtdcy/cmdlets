# Apply a diff file to an original
#
# shellcheck disable=SC2034

# Git for Windows includes a native patch.exe
libs_targets=(! windows)

libs_lic=GPLv3+
libs_ver=2.8
libs_url=(
    https://mirrors.ustc.edu.cn/gnu/patch/patch-$libs_ver.tar.xz
    https://ftpmirror.gnu.org/gnu/patch/patch-$libs_ver.tar.xz
)
libs_sha=f87cee69eec2b4fcbf60a396b030ad6aa3415f192aa5f7ee84cad5e11f7f5ae3
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # disable these for single static executables.
    --disable-nls

    --disable-doc
    --disable-man
)

libs_build() {
    libs.requires -Wno-incompatible-pointer-types

    configure

    make

    cmdlet.install  ./src/patch

    cmdlet.check patch --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
