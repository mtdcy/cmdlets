# GNU implementation of the famous stream editor
#
# shellcheck disable=SC2034

libs_lic=GPLv3+
libs_ver=4.10
libs_url=(
    https://mirrors.ustc.edu.cn/gnu/sed/sed-$libs_ver.tar.xz
    https://ftpmirror.gnu.org/gnu/sed/sed-$libs_ver.tar.xz
)
libs_sha=b8e72182b2ec96a3574e2998c47b7aaa64cc20ce000d8e9ac313cc07cecf28c7
libs_dep=(libiconv)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --without-selinux
    --disable-acl

    # always disable nls for single static executable, or
    #  => PREFIX/share/locale will hardcoded into executable
    --disable-nls

    #--without-libiconv-prefix

    # no nls or i18n
    --disable-nls
    --disable-i18n
    --without-libintl-prefix

    --disable-doc
    --disable-man
)

libs_build() {
    if is_mingw; then
        export LIBS="-lbcrypt"

        sed -i Makefile.in \
            -e '/SEDBIN =/s/$/&\$(EXEEXT)/'
    fi

    configure

    make

    # install as gsed and symlink to sed
    cmdlet.install sed/sed gsed sed

    cmdlet.check gsed --version

    # simple test
    echo "HelloWorld" > hello.txt
    echo "s/World/Hello/g" > sub.sed

    [ "$(run sed -f sub.sed hello.txt)" = "HelloHello" ] || die "sed test failed."
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
