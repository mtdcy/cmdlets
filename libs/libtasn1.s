
#
# shellcheck disable=SC2034
libs_lic='LGPL'
libs_ver=4.21.0
libs_url=https://ftpmirror.gnu.org/gnu/libtasn1/libtasn1-$libs_ver.tar.gz
libs_sha=1d8a444a223cc5464240777346e125de51d8e6abf0b8bac742ac84609167dc87

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
