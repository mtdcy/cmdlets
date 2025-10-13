# Cross-platform Rust rewrite of the GNU coreutils

# shellcheck disable=SC2034
libs_name=coreutils
libs_lic="MIT"
libs_ver=0.2.2
libs_url=https://github.com/uutils/coreutils/archive/refs/tags/$libs_ver.tar.gz
libs_zip=$libs_name-$libs_ver.tar.gz
libs_sha=4a847a3aaf241d11f07fdc04ef36d73c722759675858665bc17e94f56c4fbfb3
libs_dep=()

utils=(
    arch base32 base64 
    cat echo cp rm ln install
    readlink unlink realpath
    uniq numfmt 
)

libs_args=(
    --release
    --verbose
    
    --no-default-features
    --features "'${utils[*]}'"
)

libs_build() {
    cargo build &&

    cmdlet $(find target -name coreutils) coreutils "${utils[@]}" &&

    check coreutils --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
