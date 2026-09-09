# General-purpose data compression with high compression ratio
# shellcheck disable=SC2034

libs_name=xz
libs_lic="BSD"
libs_ver=5.8.3
libs_url=(
    https://github.com/tukaani-project/xz/releases/download/v$libs_ver/xz-$libs_ver.tar.xz
    https://downloads.sourceforge.net/project/lzmautils/xz-$libs_ver.tar.xz
    https://mirrors.wikimedia.org/ubuntu/pool/main/x/xz-utils/xz-utils_$libs_ver.orig.tar.xz
)
libs_sha=fff1ffcf2b0da84d308a14de513a1aa23d4e9aa3464d17e64b9714bfdd0bbfb6
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

    # libraries
    cmdlet.pkgfile liblzma  -- make install -C src/liblzma

    # binaries and links
    cmdlet.pkgfile lzmainfo -- make install-exec -C src/lzmainfo
    cmdlet.pkgfile xz       -- make install-exec -C src/xz
    cmdlet.pkgfile xzdec    -- make install-exec -C src/xzdec

    # scripts and links
    cmdlet.pkgfile scripts  -- make install-exec -C src/scripts

    # simple test
    echo "test" > foo && rm -f foo.xz
    cmdlet.verify xz << EOF
    xz --version
    xz foo                                  || die "xz compress failed."
    xz -t foo.xz                            || die "xz integrity test failed."
    xz -l foo.xz | grep -Fwq foo            || die "xz list contents failed."
    # FIXME: (stdout): Write error: Input/output error
    xz -d -c foo.xz | grep -Eq "^test$"     || sloge "xz decompress failed."
EOF
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
