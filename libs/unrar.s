# GNU implementation of the famous stream editor
#
# shellcheck disable=SC2034

libs_lic='UnRAR'
libs_ver=7.0.9
libs_url=https://www.rarlab.com/rar/unrarsrc-$libs_ver.tar.gz
libs_sha=505c13f9e4c54c01546f2e29b2fcc2d7fabc856a060b81e5cdfe6012a9198326
libs_dep=()

libs_args=(
    PREFIX="'$PREFIX'"

    CXX="'$CXX'"
    CXXFLAGS="'$CXXFLAGS'" 
    CPPFLAGS="'$CPPFLAGS'"
    LDFLAGS="'$LDFLAGS'"

    AS="'$AS'"
    STRIP="'$STRIP'"
)

libs_build() {
    is_clang || sed 's/-Wno-logical-op-parentheses/-Wno-parentheses/g' -i Makefile

    make -f makefile "${libs_args[@]}" &&

    # quick check
    ./unrar | grep "${libs_ver%.*}" &&

    # install
    cmdlet unrar &&

    # visual verify
    check unrar -version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
