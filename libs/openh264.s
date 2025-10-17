# BSD
#
# shellcheck disable=SC2034

libs_ver=1.8.0
libs_url=https://github.com/cisco/openh264/archive/v$libs_ver.tar.gz
libs_sha=08670017fd0bb36594f14197f60bebea27b895511251c7c64df6cd33fc667d34

libs_args=(
    PREFIX="'$PREFIX'"

    CC="'$CC'"
    CXX="'$CXX'"
    CFLAGS="'$CFLAGS'" 
    CXXFLAGS="'$CXXFLAGS'" 
    CPPFLAGS="'$CPPFLAGS'"
    LDFLAGS="'$LDFLAGS'"

    AS="'$AS'"
)

libs_build() {
    make "${libs_args[@]}" &&

    pkgfile libopenh264 -- make install-static "${libs_args[@]}" &&
    
    cmdlet ./h264dec &&
    cmdlet ./h264enc &&

    check h264dec
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
