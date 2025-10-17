# General-purpose data compression with high compression ratio
# shellcheck disable=SC2034

libs_name=xz
libs_lic="BSD"
libs_ver=5.8.1
libs_url=(
    https://github.com/tukaani-project/xz/releases/download/v$libs_ver/xz-$libs_ver.tar.xz
    https://downloads.sourceforge.net/project/lzmautils/xz-$libs_ver.tar.xz
    https://mirrors.wikimedia.org/ubuntu/pool/main/x/xz-utils/xz-utils_$libs_ver.orig.tar.xz
)
libs_sha=0b54f79df85912504de0b14aec7971e3f964491af1812d83447005807513cd9e
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
    pkgfile liblzma  -- make install -C src/liblzma  &&

    # binaries and links
    pkgfile lzmainfo -- make install -C src/lzmainfo &&
    pkgfile xz       -- make install -C src/xz       &&
    pkgfile xzdec    -- make install -C src/xzdec    &&

    # scripts and links
    pkgfile scripts  -- make install -C src/scripts  &&

    # visual verify
    check xz --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
