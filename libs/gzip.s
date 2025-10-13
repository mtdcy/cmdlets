# shellcheck disable=SC2034
upkg_name=gzip
upkg_desc="Popular GNU data compression program"

upkg_lic='GPL-3.0-or-later'
upkg_ver=1.14
upkg_url=(
    https://ftpmirror.gnu.org/gnu/gzip/gzip-$upkg_ver.tar.xz
    # mirrors
    https://ftp.gnu.org/gnu/gzip/gzip-$upkg_ver.tar.xz
    https://mirrors.ustc.edu.cn/gnu/gzip/gzip-$upkg_ver.tar.xz
)
upkg_sha=01a7b881bd220bfdf615f97b8718f80bdfd3f6add385b993dcf6efd14e8c0ac6
upkg_dep=()

upkg_args=(
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

)

upkg_static() {
    configure &&

    make &&

    {
        is_linux && make check || true
    } &&

    library gzip.h lzw.h lib/libgzip.a &&

    cmdlet gzip &&
    cmdlet gunzip &&
    cmdlet gzexe &&
    cmdlet zcat &&
    cmdlet zcmp &&
    cmdlet zdiff &&
    cmdlet zgrep &&
    cmdlet zegrep &&
    cmdlet zfgrep &&
    cmdlet zmore &&
    cmdlet zless &&
    cmdlet znew &&

    check gzip
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
