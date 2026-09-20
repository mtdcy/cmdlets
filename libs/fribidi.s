# LGPL 2.1
# for libass
#
# shellcheck disable=SC2034

libs_lic=LGPL
libs_ver=1.0.17
libs_rev=1
libs_url=https://github.com/fribidi/fribidi/releases/download/v$libs_ver/fribidi-$libs_ver.tar.xz
libs_sha=6949dcde27d41cebad1fd741fcafc36d55a1020d2d872d4a6eb3914caabbada2

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

    cmdlet.pkgfile libfribidi -- make install SUBDIRS=lib

    cmdlet.install bin/fribidi

    cmdlet.verify -- fribidi

    echo "a _lsimple _RteST_o th_oat" > test.input || die

    # CRLF(windows) vs LF(*nix) => sed CRLF to LF
    output=$(./bin/fribidi$_BINEXT --charset=CapRTL --test test.input | sed 's/\r$//')

    echo "|$output|"

    [ "${output#*=> }" = "a simple TSet that" ] || die "simple test failed."
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
