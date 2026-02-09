# LGPL 2.1
# for libass
#
# shellcheck disable=SC2034

libs_lic=LGPL
libs_ver=1.0.16
libs_url=https://github.com/fribidi/fribidi/releases/download/v$libs_ver/fribidi-$libs_ver.tar.xz
libs_sha=1b1cde5b235d40479e91be2f0e88a309e3214c8ab470ec8a2744d82a5a9ea05c

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules

    --disable-debug

    --enable-static
    --disable-shared
)

libs_build() {
    configure

    make

    pkgfile libfribidi -- make.install SUBDIRS=lib

    cmdlet.install bin/fribidi

    cmdlet.check fribidi

    echo "a _lsimple _RteST_o th_oat" > test.input || die

    # CRLF(windows) vs LF(*nix) => sed CRLF to LF
    output=$(./bin/fribidi$_BINEXT --charset=CapRTL --test test.input | sed 's/\r$//')

    echo "|$output|"

    [ "${output#*=> }" = "a simple TSet that" ] || die "simple test failed."
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
