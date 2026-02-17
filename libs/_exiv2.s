# EXIF and IPTC metadata manipulation library and tools
#  replacement for exiftool which is perl scripts

# shellcheck disable=SC2034
libs_lic="GPLv2.0+"
libs_ver=0.28.7
libs_url=https://github.com/Exiv2/exiv2/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=5e292b02614dbc0cee40fe1116db2f42f63ef6b2ba430c77b614e17b8d61a638
libs_dep=( zlib expat brotli inih libiconv )

# configure args
libs_args=(
    # features
    -DEXIV2_ENABLE_INIH=ON
    -DEXIV2_ENABLE_BROTLI=ON
    -DEXIV2_ENABLE_PNG=ON

    #-Diconv=enabled

    # BMFF types such as AVIF, CR3, HEIF and HEIC
    -DEXIV2_ENABLE_BMFF=ON
    #-DEXIV2_ENABLE_EXTERNAL_XMP=ON
    -DEXIV2_ENABLE_XMP=ON

    # Support of video files is limited. Currently exiv2 only has some rudimentary support to read metadata from quicktime, matroska and riff based video files
    -DEXIV2_ENABLE_VIDEO=OFF

    # no webready => keep it simple
    -DEXIV2_ENABLE_WEBREADY=OFF

    # disabled features
    -DDEXIV2_ENABLE_NLS=OFF
    -DDEXIV2_BUILD_SAMPLES=OFF

    # static only
    -DBUILD_SHARED_LIBS=OFF
)

# shellcheck disable=SC2086
libs_build() {
    # ERROR: Dependency "iconv" not found
    #export LDFLAGS+=" -liconv"

    cmake.setup

    cmake.build

    # Fix libiconv dependency
    pkgconf -liconv

    pkgfile libexiv2 -- cmake.install

    cmdlet.install bin/exiv2

    cmdlet.check exiv2 --version --verbose
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
