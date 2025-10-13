# GNU implementation of the famous stream editor
#
# shellcheck disable=SC2034

upkg_lic='UnRAR'
upkg_ver=7.0.9
upkg_url=https://www.rarlab.com/rar/unrarsrc-$upkg_ver.tar.gz
upkg_sha=505c13f9e4c54c01546f2e29b2fcc2d7fabc856a060b81e5cdfe6012a9198326
upkg_dep=()

upkg_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking
)

upkg_static() {
    echocmd sed -i makefile           \
        -e 's/^CXX=/CXX?=/'           \
        -e 's/^AR=/AR?=/'             \
        -e 's/^CXXFLAGS=/CXXFLAGS+=/' \
        -e 's/^STRIP=/STRIP?=/'       \
        -e 's/^LDFLAGS=/LDFLAGS+=/'   \

    is_clang || sed 's/-Wno-logical-op-parentheses/-Wno-parentheses/g' -i Makefile

    make -f makefile &&

    # quick check
    ./unrar | grep "${upkg_ver%.*}" &&

    # install
    cmdlet unrar &&

    # visual verify
    check unrar -version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
