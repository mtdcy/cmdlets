# File comparison utilities

# shellcheck disable=SC2034

libs_lic=GPLv3+
libs_ver=3.12
libs_url=(
    https://mirrors.tuna.tsinghua.edu.cn/gnu/diffutils/diffutils-3.12.tar.xz
    https://ftpmirror.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz
)
libs_sha=7c8b7f9fc8609141fdea9cece85249d308624391ff61dedaf528fcb337727dfd

libs_deps=()

libs_args=(
    --disable-dependency-tracking
)

libs_build() {
    # disclaim rust diffutils versions
    cmdlet.disclaim 0.5.0

    configure 

    make

    for x in cmp diff diff3; do
        cmdlet.install "src/$x"
    done

    # rust diffutils has no `--version'
    cmdlet.check diff --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
