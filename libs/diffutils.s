# File comparison utilities

# shellcheck disable=SC2034

libs_lic=GPLv3+
libs_ver=3.12
libs_url=${LIBS_MIRROR_GNU:-https://ftpmirror.gnu.org/gnu}/diffutils/diffutils-3.12.tar.xz
libs_sha=7c8b7f9fc8609141fdea9cece85249d308624391ff61dedaf528fcb337727dfd

libs_args=(
    --prefix="$PREFIX"

    --disable-nls
    --without-libintl-prefix
    --without-libiconv-prefix

    # no large files
    # error: conflicting types for 'off64_t'; have 'long long int
    --disable-largefile
)

# NEVER run conftest.exe
is_xbuild && libs_args+=(
    gl_cv_func_strcasecmp_works=yes
)

is_cygwin && libs_args+=(--host=$(uname -m)-pc-cygwin)

libs_build() {
    # disclaim rust diffutils versions
    cmdlet.disclaim 0.5.0

    slogcmd ./configure "${libs_args[@]}" || die "configure failed"

    make

    diffutils=(cmp diff diff3 sdiff)

    # install diff utils
    for x in "${diffutils[@]}"; do
        cmdlet.install src/$x
    done

    # pack all together
    cmdlet.pkgfile diffutils $(printf "bin/%s " "${diffutils[@]}")

    # rust diffutils has no `--version'
    cmdlet.verify -- diff --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
