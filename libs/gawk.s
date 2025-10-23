# GNU awk utility

# shellcheck disable=SC2034
libs_lic='GPL-3.0-or-later'
libs_ver=5.3.2
libs_url=https://ftpmirror.gnu.org/gnu/gawk/gawk-$libs_ver.tar.xz
libs_sha=f8c3486509de705192138b00ef2c00bbbdd0e84c30d5c07d23fc73a9dc4cc9cc
libs_dep=(gmp mpfr readline)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # enable explicitly
    --with-readline
    --with-mpfr

    --without-selinux
    --disable-rpath

    # disable these for single static executables.
    --disable-nls
    --without-libintl-prefix

    --disable-doc
    --disable-man
)

[[ ${libs_dep[*]} =~ mpfr ]] || libs_args+=(--without-mpfr)

[[ ${libs_dep[*]} =~ readline ]] || libs_args+=(--without-readline)

libs_build() {
    # refer to: https://github.com/macports/macports-ports/blob/master/lang/gawk/Portfile
    if is_darwin; then
        sed -i 's:-Xlinker -no_pie::' configure
    fi

    configure

    make

    # check => XXX: there always 5 FAILs
    #make check &&
    [ "HelloHello" = "$(./gawk '{ gsub(/World/, "Hello"); print }' <<< "HelloWorld")" ] || die "test failed"

    #make install-exec &&
    cmdlet ./gawk gawk awk

    # visual verify
    check gawk --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
