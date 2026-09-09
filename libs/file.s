# Implementation of the file(1) command

# depends on ubuntu patches
libs_stable=1

# shellcheck disable=SC2034
libs_lic="BSD-2-Clause"
libs_ver=5.46
libs_url=https://astron.com/pub/file/file-$libs_ver.tar.gz
libs_sha=c9cc77c7c560c543135edc555af609d5619dbef011997e988ce40a3d75d86088
libs_deps=(zlib bzip2 xz zstd)

# https://mirrors.wikimedia.org/ubuntu/pool/main/f/file/
libs_resources=(
    "https://mirrors.wikimedia.org/ubuntu/pool/main/f/file/file_5.46-5build1.debian.tar.xz|d04f215fd64a3cddd3b85b3a111c0b0a3bd0d8f58030453a2e0df061f225dbeb"
)

libs_patches=(
    # cherry-picked commits. Keep in upstream's chronological order
    debian/patches/1733423740.FILE5_46-7-gb3384a1f.pr-579-net147-fix-stack-overrun.patch
    debian/patches/1733427672.FILE5_46-14-g60b2032b.pr-571-jschleus-some-zip-files-are-misclassified-as-data.patch
    debian/patches/1741021322.FILE5_46-55-gff9ba253.use-unsigned-byte-christoph-biedl.patch
    #debian/patches/1742485595.FILE5_46-68-g5089651f.fix-openstreetmap-christoph-biedl.patch
    debian/patches/1742492756.FILE5_46-69-g280e121f.remove-superfluous-christoph-biedl.patch
    debian/patches/1742492810.FILE5_46-70-g4e2c7d3d.fix-msdosdate-endianess.patch

    # patches that should go upstream
    debian/patches/upstream.disable.att3b.patch
    debian/patches/upstream.stricter-postscript-magic.patch
)

libs_args=(
    --enable-static --disable-shared

    --enable-fsect-man5
)

is_listed zlib  "${libs_deps[@]}" && libs_args+=(--enable-zlib)      || libs_args+=(--disable-zlib)
is_listed bzip2 "${libs_deps[@]}" && libs_args+=(--enable-bzlib)     || libs_args+=(--disable-bzlib)
is_listed xz    "${libs_deps[@]}" && libs_args+=(--enable-xzlib)     || libs_args+=(--disable-xzlib)
is_listed zstd  "${libs_deps[@]}" && libs_args+=(--enable-zstdlib)   || libs_args+=(--disable-zstdlib)
is_listed lzip  "${libs_deps[@]}" && libs_args+=(--enable-lzlib)     || libs_args+=(--disable-lzlib)

libs_build() {
    # compile native file first
    if is_xbuild; then
        (   
            unset CC CFLAGS CPPFLAGS LDFLAGS
            mkdir -pv .host && cd .host
            CC="$HOSTCC" ../configure && $MAKE -C src
        ) || die "build native file failed"
    fi

    configure

    # it seems the dependencies checking is broken
    touch src/magic.c

    # magic 文件并不通用，同时也避免加载主机的 magic.mgc
    #  => 使用 /lib 而非 /usr/share
    MAGIC_PATH=lib/file-$libs_ver

    # make file.exe first
    make -C src pkgdatadir=/$MAGIC_PATH MAGIC=/$MAGIC_PATH/magic.mgc

    # make magic.mgc
    #  PATH : 使用上面编译的而非主机自带的 file
    if is_xbuild; then
        make -C magic FILE_COMPILE="$PWD/.host/src/file"
    else
        make -C magic FILE_COMPILE="$PWD/src/file"
    fi

    # install libmagic
    cmdlet.pkgfile libmagic -- make install -C src bin_PROGRAMS=

    # install file program
    if is_cygwin; then
        cmdlet.pkginst  file \
            bin         src/file \
            $MAGIC_PATH magic/magic.mgc
    else
        # Linux: make an entry point
        cat << EOF > file
#!/bin/sh
DIR=\$(dirname "\$0")/../$MAGIC_PATH
MAGIC="\$DIR/magic.mgc" exec "\$DIR/file" "\$@"
EOF
        chmod a+x file

        cmdlet.pkginst  file \
            bin         file \
            $MAGIC_PATH src/file magic/magic.mgc
    fi

    cmdlet.verify -- file --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
