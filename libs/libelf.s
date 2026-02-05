# ELF object file access library
#
# shellcheck disable=SC2034
libs_lic=LGPLv2+
libs_ver=0.8.13
libs_url=https://fossies.org/linux/misc/old/libelf-0.8.13.tar.gz
libs_sha=591a9b4ec81c1f2042a97aa60564e0cb79d041c52faa7416acb38bc95bd2c76d
libs_dep=( )

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --disable-compat

    # static only
    --disable-shared
    --enable-static
)

libs_build() {

    slogcmd autoreconf -fiv

    configure

    make

    # libelf Makefile do not support DESTDIR
    pkginst "$libs_name" \
            include/libelf  lib/{libelf.h,nlist.h,gelf.h,sys_elf.h,elf_repl.h} \
            lib             lib/libelf.a \
            lib/pkgconfig   libelf.pc
}

# Linux use elfutils
libs.depends is_darwin

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
