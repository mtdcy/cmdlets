# shellcheck disable=SC2034
libs_name=gzip
libs_desc="Popular GNU data compression program"

libs_lic='GPL-3.0-or-later'
libs_ver=1.14
libs_url=(
    https://ftpmirror.gnu.org/gnu/gzip/gzip-$libs_ver.tar.xz
    # mirrors
    https://ftp.gnu.org/gnu/gzip/gzip-$libs_ver.tar.xz
    https://mirrors.ustc.edu.cn/gnu/gzip/gzip-$libs_ver.tar.xz
)
libs_sha=01a7b881bd220bfdf615f97b8718f80bdfd3f6add385b993dcf6efd14e8c0ac6
libs_dep=()

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --without-selinux
    --disable-acl

    # always disable nls for single static executable, or
    #  => PREFIX/share/locale will hardcoded into executable
    --disable-nls

)

libs_build() {
    configure && make &&  make check || return $?

    pkginst libgzip gzip.h lzw.h lib/libgzip.a &&

    cmdlet gzip   &&
    cmdlet gunzip &&
    cmdlet gzexe  &&
    cmdlet zcat   &&
    cmdlet zcmp   &&
    cmdlet zdiff  &&
    cmdlet zgrep  &&
    cmdlet zegrep &&
    cmdlet zfgrep &&
    cmdlet zmore  &&
    cmdlet zless  &&
    cmdlet znew   &&

    check gzip
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
