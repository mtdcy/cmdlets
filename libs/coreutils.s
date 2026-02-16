# Cross-platform Rust rewrite of the GNU coreutils

# shellcheck disable=SC2034
libs_name=coreutils
libs_lic="MIT"
libs_ver=0.6.0
libs_url=https://github.com/uutils/coreutils/archive/refs/tags/$libs_ver.tar.gz
libs_sha=f751b8209ec05ae304941a727e42a668dcc45674986252f44d195ed43ccfad2f
libs_dep=( libiconv )

# multicall core utils
uu_links=(
    # basic
    ls rm cp yes true
    # print
    echo printf
    # path
    pwd basename dirname
    # files
    cat tee tail 
    # utils
    sort uniq cut tr wc
)

# symbolic link related
is_mingw || uu_links+=( 
    install ln unlink readlink realpath
)

# standalone utils
uu_utils=(
    numfmt nproc
    more date
)

# md5 and sha
uu_utils+=(
    base32 
    base64
    md5sum
    sha1sum
    sha256sum
    sha512sum
)

libs_args=(
    --release
    --verbose
)

#if is_mingw; then
#    libs_args+=( --features windows )
#else
#    libs_args+=( --features "'${uu_links[*]} ${uu_utils[*]}'" )
#fi

libs_build() {
    # libiconv has no pc file
    # export LIBICONV_NO_PKG_CONFIG=1
    export LIBICONV_STATIC=1

    cargo.setup

    cargo.build --features "'${uu_links[*]}'"

    cmdlet.install $(cargo.locate coreutils) coreutils "${uu_links[@]}"

    for x in "${uu_utils[@]}"; do
        cargo.build -p "uu_$x"
        cmdlet.install $(cargo.locate $x)
    done

    cmdlet.check coreutils --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
