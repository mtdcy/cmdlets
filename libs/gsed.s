# GNU implementation of the famous stream editor
#
# shellcheck disable=SC2034

libs_lic='GPL-3.0-or-later'
libs_ver=4.9
libs_url=https://ftpmirror.gnu.org/gnu/sed/sed-$libs_ver.tar.xz
libs_sha=6e226b732e1cd739464ad6862bd1a1aba42d7982922da7a53519631d24975181
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
    # disable rpath for single static executable
    --disable-rpath

    #--without-libiconv-prefix
    #--without-libintl-prefix

    --disable-doc
    --disable-man

    # install as 'gsed'
    --program-prefix=g
)

libs_build() {
    configure && make &&

    # install as gsed and symlink to sed
    cmdlet sed/sed gsed sed &&

    check gsed --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
