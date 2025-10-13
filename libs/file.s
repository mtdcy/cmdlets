# Implementation of the file(1) command

# shellcheck disable=SC2034
libs_ver=5.46
libs_url=(
    "https://astron.com/pub/file/file-$libs_ver.tar.gz"
)
libs_sha=c9cc77c7c560c543135edc555af609d5619dbef011997e988ce40a3d75d86088
libs_lic="BSD-2-Clause"
libs_dep=( zlib bzip2 xz )

# https://mirrors.wikimedia.org/ubuntu/pool/main/f/file/
libs_patch_url=https://mirrors.wikimedia.org/ubuntu/pool/main/f/file/file_5.46-5build1.debian.tar.xz
libs_patch_sha=d04f215fd64a3cddd3b85b3a111c0b0a3bd0d8f58030453a2e0df061f225dbeb

libs_patches=(
    # cherry-picked commits. Keep in upstream's chronological order
    patches/1733423740.FILE5_46-7-gb3384a1f.pr-579-net147-fix-stack-overrun.patch
    patches/1733427672.FILE5_46-14-g60b2032b.pr-571-jschleus-some-zip-files-are-misclassified-as-data.patch
    patches/1741021322.FILE5_46-55-gff9ba253.use-unsigned-byte-christoph-biedl.patch
    patches/1742485595.FILE5_46-68-g5089651f.fix-openstreetmap-christoph-biedl.patch
    patches/1742492756.FILE5_46-69-g280e121f.remove-superfluous-christoph-biedl.patch
    patches/1742492810.FILE5_46-70-g4e2c7d3d.fix-msdosdate-endianess.patch

    # patches that should go upstream
    patches/upstream.disable.att3b.patch
    patches/upstream.stricter-postscript-magic.patch

    # ubuntu local modifications
    #patches/local.support-local-definitions-in-etc-magic.patch
    patches/local.don-t-include-libs-in-build.patch
    #patches/local.extra-magic.patch
    #patches/local.manpage-seccomp-is-disabled.patch
)

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

    --enable-fsect-man5

    --disable-shared
    --enable-static
)

# usage of the new file cmd
#
# option 1: file -m path/to/magic.mgc
# option 2: ln -srfv path/to/magic.mgc $HOME/.magic.mgc
#
# version mismatched magic.mgc may not work

libs_build() {
    MAGIC_PATH="share/misc"

    configure || return 1

    # 1. user magic ~/.magic.mgc or ~/.magic or ~/.magic/magic.mgc
    # 2. relative .magic.mgc in current dir
    # 3. normal path /usr/share/file/magic => not working
    #   'file: Size of `/usr/share/file/magic.mgc' 7273344 is not a multiple of 432'
    sed -i "s%^MAGIC = .*$%MAGIC = .magic.mgc%" src/Makefile

    # hack for our project: avoid hard coding PREFIX into libmagic.a
    ln -srfv "$PREFIX/$MAGIC_PATH/magic.mgc" "$ROOT/.magic.mgc"
    ln -srfv "$PREFIX/$MAGIC_PATH/magic.mgc" "$PREFIX/.magic.mgc"
    ln -srfv "$PREFIX/$MAGIC_PATH/magic.mgc" ".magic.mgc"

    # it seems the dependencies checking is broken
    touch src/magic.c

    make &&

    inspect make install &&

    pkgfile libmagic                  \
            include/magic.h           \
            lib/libmagic.a            \
            lib/pkgconfig/libmagic.pc \
            &&

    pkgfile magic.mgc "$MAGIC_PATH/magic.mgc" &&

    cmdlet ./src/file &&

    check file --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
