# C string library for manipulating Unicode strings
#
# shellcheck disable=SC2034
libs_lic='LGPL|GPL'
libs_ver=1.4
libs_url=https://ftpmirror.gnu.org/gnu/libunistring/libunistring-$libs_ver.tar.gz
libs_sha=f7e39ddeca18858ecdd02c60d1d5374fcdcbbcdb6b68a391f8497cb1cb2cf3f7
libs_dep=( libiconv )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    --with-libiconv
    --with-libiconv-prefix="'$PREFIX'"

    --with-pic

    --disable-rpath

    # static only
    --disable-shared
    --enable-static
)

# install to include/
common_headers=(
    lib/unicase.h
    lib/uniconv.h
    lib/uniwidth.h
    lib/unitypes.h
    lib/uninorm.h
    lib/unistr.h
    lib/unistdio.h
    lib/unigbrk.h
    lib/unimetadata.h
    lib/unilbrk.h
    lib/uniname.h
    lib/unictype.h
)

libs_build() {
    configure && make || return $?

    pkgfile libunistring -- make install SUBDIRS=lib
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
