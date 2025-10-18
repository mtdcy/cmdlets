# shellcheck disable=SC2034
libs_name="gtar"
libs_desc="GNU version of the tar archiving utility"

libs_lic='GPL-3.0-or-later'
libs_ver=1.35
libs_url=https://ftpmirror.gnu.org/gnu/tar/tar-$libs_ver.tar.xz
libs_sha=4d62ff37342ec7aed748535323930c7cf94acf71c3591882b26a7ea50f3edc16
libs_dep=(gzip bzip2 xz zstd lzip lzop libiconv)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    # always disable nls for single static executable, or
    #  => PREFIX/share/locale will hardcoded into executable
    --disable-nls
    #
    --without-selinux
    --disable-acl
    #
    --disable-doc
    --disable-man
)

is_darwin || libs_args+=(
    --disable-shared
    --enable-static
)

# rmt: avoid hardcoded $PREFIX into executable
#  => default path on Linux, no rmt on macOS.
libs_args+=(--with-rmt="/usr/sbin/rmt")

libs_build() {
    # BUG: undefined reference to `libiconv_open'
    # iconv is detected during configure process but -liconv is missing
    # from LDFLAGS as of gnu-tar 1.35. Remove once iconv linking works
    # without this. See https://savannah.gnu.org/bugs/?64441.
    # fix commit, https://git.savannah.gnu.org/cgit/tar.git/commit/?id=8632df39, remove in next release
    export LIBS="-liconv"

    configure &&

    make V=1 &&

    # simple test
    {
        echo "test" > test.txt
        ./src/tar -czvf test.tar.gz test.txt
        [ "test" = "$(./src/tar -xOzf test.tar.gz)" ]
    } &&

    # provide default 'tar' and 'gtar'
    cmdlet src/tar gtar tar &&

    # visual verify
    check gtar --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
