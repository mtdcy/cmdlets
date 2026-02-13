# General-purpose data compression with high compression ratio
# shellcheck disable=SC2034

libs_name=xz
libs_lic="BSD"
libs_ver=5.8.2
libs_url=(
    https://github.com/tukaani-project/xz/releases/download/v$libs_ver/xz-$libs_ver.tar.xz
    https://downloads.sourceforge.net/project/lzmautils/xz-$libs_ver.tar.xz
    https://mirrors.wikimedia.org/ubuntu/pool/main/x/xz-utils/xz-utils_$libs_ver.orig.tar.xz
)
libs_sha=890966ec3f5d5cc151077879e157c0593500a522f413ac50ba26d22a9a145214
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
    configure && make && make check || return $?

    # libraries
    pkgfile liblzma  -- make install -C src/liblzma

    # binaries and links
    pkgfile lzmainfo -- make install-exec -C src/lzmainfo
    pkgfile xz       -- make install-exec -C src/xz
    pkgfile xzdec    -- make install-exec -C src/xzdec

    # scripts and links
    pkgfile scripts  -- make install-exec -C src/scripts

    # visual verify
    check xz --version
    
    # simple test 
    echo "test" > foo && rm -f foo.xz
    run xz foo                                  || die "xz compress failed."
    run xz -t foo.xz                            || die "xz integrity test failed."
    run xz -l foo.xz | grep -Fwq foo            || die "xz list contents failed."
    run xz -d -c foo.xz | grep -Eq "^test$"     || die "xz decompress failed."
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
