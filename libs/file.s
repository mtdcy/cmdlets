# Implementation of the file(1) command

# shellcheck disable=SC2034
libs_lic="BSD-2-Clause"
libs_ver=5.46
libs_url=https://astron.com/pub/file/file-$libs_ver.tar.gz
libs_sha=c9cc77c7c560c543135edc555af609d5619dbef011997e988ce40a3d75d86088

libs_deps=( zlib bzip2 xz zstd )

is_mingw && libs_deps+=( libgnurx )

# https://mirrors.wikimedia.org/ubuntu/pool/main/f/file/
libs_resources=(
    "https://mirrors.wikimedia.org/ubuntu/pool/main/f/file/file_5.46-5build1.debian.tar.xz|d04f215fd64a3cddd3b85b3a111c0b0a3bd0d8f58030453a2e0df061f225dbeb"
)

libs_patches=(
    # cherry-picked commits. Keep in upstream's chronological order
    debian/patches/1733423740.FILE5_46-7-gb3384a1f.pr-579-net147-fix-stack-overrun.patch
    debian/patches/1733427672.FILE5_46-14-g60b2032b.pr-571-jschleus-some-zip-files-are-misclassified-as-data.patch
)

is_mingw || libs_patches+=(
    debian/patches/1741021322.FILE5_46-55-gff9ba253.use-unsigned-byte-christoph-biedl.patch
    #debian/patches/1742485595.FILE5_46-68-g5089651f.fix-openstreetmap-christoph-biedl.patch
    debian/patches/1742492756.FILE5_46-69-g280e121f.remove-superfluous-christoph-biedl.patch
    debian/patches/1742492810.FILE5_46-70-g4e2c7d3d.fix-msdosdate-endianess.patch

    # patches that should go upstream
    debian/patches/upstream.disable.att3b.patch
    debian/patches/upstream.stricter-postscript-magic.patch
)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-fsect-man5

    --disable-shared
    --enable-static
)

is_listed zlib  "${libs_deps[@]}" && libs_args+=( --enable-zlib    ) || libs_args+=( --disable-zlib    )
is_listed bzip2 "${libs_deps[@]}" && libs_args+=( --enable-bzlib   ) || libs_args+=( --disable-bzlib   )
is_listed xz    "${libs_deps[@]}" && libs_args+=( --enable-xzlib   ) || libs_args+=( --disable-xzlib   )
is_listed zstd  "${libs_deps[@]}" && libs_args+=( --enable-zstdlib ) || libs_args+=( --disable-zstdlib )
is_listed lzip  "${libs_deps[@]}" && libs_args+=( --enable-lzlib   ) || libs_args+=( --disable-lzlib   )

# usage of the new file cmd
#
# option 1: file -m path/to/magic.mgc
# option 2: ln -srfv path/to/magic.mgc $HOME/.magic.mgc
#
# version mismatched magic.mgc may not work

libs_build() {
    MAGIC_INSTALL_PATH="share/misc"

    configure 

    # 1. user magic ~/.magic.mgc or ~/.magic or ~/.magic/magic.mgc
    # 2. relative .magic.mgc in current dir
    # 3. normal path /usr/share/file/magic => not working
    #   'file: Size of `/usr/share/file/magic.mgc' 7273344 is not a multiple of 432'
    sed -i "s%^MAGIC = .*$%MAGIC = .magic.mgc%" src/Makefile

    # it seems the dependencies checking is broken
    touch src/magic.c

    make

    cmdlet.pkgfile libmagic -- make.install -C src bin_PROGRAMS=

    cmdlet.pkginst magic.mgc "$MAGIC_INSTALL_PATH" magic/magic.mgc

    cmdlet.install src/file 

    cmdlet.check file --version

    caveats << EOF
file @ $libs_ver

magic file from ~/.magic.mgc:.magic.mgc only

file needs magic.mgc to work properly:

cmdlets.sh install magic.mgc
cmdlets.sh link $MAGIC_INSTALL_PATH/magic.mgc ~/.magic.mgc
EOF
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
