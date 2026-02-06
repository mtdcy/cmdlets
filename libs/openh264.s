# H.264 codec from Cisco
#
# shellcheck disable=SC2034
libs_lic="BSD-2-Clause"
libs_ver=2.6.0
libs_url=https://github.com/cisco/openh264/archive/v$libs_ver.tar.gz
libs_sha=558544ad358283a7ab2930d69a9ceddf913f4a51ee9bf1bfb9e377322af81a69

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
    make "${libs_args[@]}"

    pkgfile libopenh264 -- make install-static "${libs_args[@]}"

    for x in h264dec h264enc; do
        cmdlet.install "$x"
        cmdlet.check "$x"
    done
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
