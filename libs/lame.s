# High quality MPEG Audio Layer III (MP3) encoder

# shellcheck disable=SC2034
libs_lic="LGPLv2+"
libs_ver=4.0
libs_url=https://sourceforge.net/projects/lame/files/lame/$libs_ver/lame-$libs_ver.tar.gz
libs_sha=3df5124d5ad3a98312ffd7ba6a9b36230e4f8a3e66d3ce0f425e336c32d216eb

#libs_depends=(ncurses)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # 彻底关闭 LAME 的解码部分
    # 直接斩断与 mpg123、gettext 等任何第三方解码库的纠缠。
    --disable-decoder

    --disable-shared
    --enable-static
)

is_arm64 || libs_args+=(--enable-nasm)

# lame command line tool
is_listed ncurses libs_depends || libs_args+=(--disable-frontend)

libs_build() {
    # LAME still calls undeclared legacy ID3 APIs, which do not compile as C23.
    # https://sourceforge.net/p/lame/bugs/517/
    export ac_cv_prog_cc_c23="no"

    # Fix undefined symbol error _lame_init_old
    # https://sourceforge.net/p/lame/mailman/message/36081038/
    sed -i '/lame_init_old/d' include/libmp3lame.sym

    configure

    make

    make check

    cmdlet.pkgfile libmp3lame -- make.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
