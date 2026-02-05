# Cross-platform Rust rewrite of the GNU coreutils

# shellcheck disable=SC2034
libs_name=coreutils
libs_lic="MIT"
libs_ver=0.6.0
libs_url=https://github.com/uutils/coreutils/archive/refs/tags/$libs_ver.tar.gz
libs_sha=f751b8209ec05ae304941a727e42a668dcc45674986252f44d195ed43ccfad2f
libs_dep=( libiconv )

# override bsd utils
uu_links=(
    ls rm cp install
    ln readlink unlink realpath
    sort uniq cut tr wc
)

# df: do not print real stat on macOS
uu_utils=(
    base32 base64
    numfmt nproc
    more
)

libs_args=(
    --release
    --verbose

    --no-default-features
    --features "'${uu_links[*]} ${uu_utils[*]}'"
)

libs_build() {
    # libiconv has no pc file
    export LIBICONV_NO_PKG_CONFIG=1
    export LIBICONV_STATIC=1

    cargo build

    cmdlet "$(find target -name coreutils)" coreutils "${uu_links[@]}"

    for x in "${uu_utils[@]}"; do
        cmdlet "$(find target -name coreutils)" "$x"
    done

    check coreutils --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
