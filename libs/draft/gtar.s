# shellcheck disable=SC2034
libs_name="gtar"
libs_desc="GNU version of the tar archiving utility"

libs_lic='GPL-3.0-or-later'
libs_ver=1.35
libs_url=https://ftpmirror.gnu.org/gnu/tar/tar-$libs_ver.tar.xz
libs_sha=4d62ff37342ec7aed748535323930c7cf94acf71c3591882b26a7ea50f3edc16

libs_deps=(gzip bzip2 xz zstd lzip lzop libiconv)

# patch manually
libs_resources=(
    https://github.com/msys2/MSYS2-packages/raw/767cd8c7afadbbdaa45b4bd7e5e39a4a5f4cf2c6/tar/tar-1.33-textmount.patch

    # Backport from paxutils which is vendored:
    # https://cgit.git.savannah.gnu.org/cgit/paxutils.git/commit/?id=063408cc6f32fff79b4f436a62236b84ca442d2e
    https://github.com/msys2/MSYS2-packages/raw/767cd8c7afadbbdaa45b4bd7e5e39a4a5f4cf2c6/tar/paxutils-Prevent-file-name-escape.patch
)

is_mingw && libs_resources+=(
    https://gist.githubusercontent.com/Cr4sh/126d844c28a7fbfd25c6/raw/32787dc2dcc1a55ba23d7f974c18936fc40c25aa/fork.c
)

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

is_linux || libs_args+=( --without-xattrs )

is_mingw && libs_args+=( --build=x86_64-linux-gnu )

# rmt: avoid hardcoded $PREFIX into executable
#  => default path on Linux, no rmt on macOS.
#libs_args+=(--with-rmt="/usr/sbin/rmt")

libs_build() {
    slogcmd "$PATCH" -p2 -i tar-1.33-textmount.patch
    slogcmd "$PATCH" -bp1 -i paxutils-Prevent-file-name-escape.patch

    # BUG: undefined reference to `libiconv_open'
    # iconv is detected during configure process but -liconv is missing
    # from LDFLAGS as of gnu-tar 1.35. Remove once iconv linking works
    # without this. See https://savannah.gnu.org/bugs/?64441.
    # fix commit, https://git.savannah.gnu.org/cgit/tar.git/commit/?id=8632df39, remove in next release
    export LIBS="-liconv"

    configure

    make V=1

    # simple test
    {
        echo "test" > test.txt
        run src/tar -czvf test.tar.gz test.txt
        [ "test" = "$(run src/tar -xOzf test.tar.gz)" ]
    } || die "gtar test failed."

    # provide default 'tar' and 'gtar'
    cmdlet.install src/tar gtar tar 

    # visual verify
    cmdlet.check gtar --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
