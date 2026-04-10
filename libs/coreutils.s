# Cross-platform Rust rewrite of the GNU coreutils

libs_stable=1

# shellcheck disable=SC2034
libs_name=coreutils
libs_lic="MIT"
libs_ver=0.7.0
libs_url=https://github.com/uutils/coreutils/archive/refs/tags/$libs_ver.tar.gz
libs_sha=dc56a3c4632742357d170d60a7dcecb9693de710daeaafa3ad925750b1905522
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
    # v0.8.0: tee is broken
    cmdlet.disclaim 0.8.0

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
