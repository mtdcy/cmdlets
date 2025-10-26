# Regular expressions library
#
# shellcheck disable=SC2034
libs_name=oniguruma
libs_lic="BSD-2-Clause"
libs_ver=6.9.11
libs_url=https://github.com/kkos/oniguruma/releases/download/v6.9.10/onig-6.9.10.tar.gz
libs_sha=2a5cfc5ae259e4e97f86b68dfffc152cdaffe94e2060b770cb827238d769fc05
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # no these for single static executables.
    --disable-nls

    --disable-shared
    --enable-static
)

libs_build() {
    configure

    make

    pkgfile libonig -- make install bin_SCRIPTS=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
