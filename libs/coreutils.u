# Cross-platform Rust rewrite of the GNU coreutils

# shellcheck disable=SC2034
upkg_name=coreutils
upkg_lic="MIT"
upkg_ver=0.2.2
upkg_url=https://github.com/uutils/coreutils/archive/refs/tags/$upkg_ver.tar.gz
upkg_zip=$upkg_name-$upkg_ver.tar.gz
upkg_sha=4a847a3aaf241d11f07fdc04ef36d73c722759675858665bc17e94f56c4fbfb3
upkg_dep=()

utils=(
    arch base32 base64 
    cat echo cp rm ln install
    readlink unlink realpath
    uniq numfmt 
)

upkg_args=(
    --release
    --verbose
    
    --no-default-features
    --features "'${utils[*]}'"
)

upkg_static() {
    cargo build &&

    cmdlet $(find target -name coreutils) coreutils "${utils[@]}" &&

    check coreutils --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
