
#
# shellcheck disable=SC2034
libs_lic='LGPL'
libs_ver=4.20.0
libs_url=https://ftpmirror.gnu.org/gnu/libtasn1/libtasn1-$libs_ver.tar.gz
libs_sha=92e0e3bd4c02d4aeee76036b2ddd83f0c732ba4cda5cb71d583272b23587a76c

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # static only
    --disable-shared
    --enable-static
)

libs_build() {
    configure && make || return $?
    
    # make install SUBDIRS=lib fails
    sed -i 's/^SUBDIRS =.*$/SUBDIRS = lib/' Makefile

    pkgfile libtasn1 -- make install &&

    cmdlet src/asn1Coding            &&
    cmdlet src/asn1Decoding          &&
    cmdlet src/asn1Parser            &&

    check asn1Coding --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
