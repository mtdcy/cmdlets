# EXIF and IPTC metadata manipulation library and tools
#  replacement for exiftool which is perl scripts

# meson.build:23:4: ERROR: Problem encountered: Non UCRT MinGW is unsupported. Please update toolchain
#  TODO: prepare ucrt
libs_targets=( linux darwin )

# shellcheck disable=SC2034
libs_lic="GPLv2.0+"
libs_ver=0.28.7
libs_url=https://github.com/Exiv2/exiv2/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=5e292b02614dbc0cee40fe1116db2f42f63ef6b2ba430c77b614e17b8d61a638
libs_dep=( zlib expat brotli inih libiconv )

# configure args
libs_args=(
    -Diconv=enabled
    -Dinih=enabled

    -Dpng=enabled       # Build with PNG support (requires zlib)
    -Dbrotli=enabled    # Google brotli
    -Dxmp=enabled       # Build with BMFF support

    # BMFF types such as AVIF, CR3, HEIF and HEIC
    -Dbmff=true

    # Support of video files is limited. Currently exiv2 only has some rudimentary support to read metadata from quicktime, matroska and riff based video files
    -Dvideo=false

    # no webready => keep it simple
    -Dwebready=false

    -Dnls=disabled
    -DunitTests=disabled
)

# shellcheck disable=SC2086
libs_build() {
    # ERROR: Dependency "iconv" not found
    export LDFLAGS+=" -liconv"

    meson.setup

    meson.compile

    # Fix libiconv dependency
    sed -e '/Requires:/s/$/& libiconv/' \
        -i meson-private/exiv2.pc || die

    pkgfile libexiv2 -- meson.install --tags devel

    cmdlet.install exiv2

    cmdlet.check exiv2 --version --verbose
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
