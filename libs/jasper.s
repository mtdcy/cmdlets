# Library for manipulating JPEG-2000 images

# shellcheck disable=SC2034
libs_ver=4.2.8
libs_url=https://github.com/jasper-software/jasper/releases/download/version-$libs_ver/jasper-$libs_ver.tar.gz
libs_sha=98058a94fbff57ec6e31dcaec37290589de0ba6f47c966f92654681a56c71fae
libs_dep=( libjpeg-turbo )

# configure args
libs_args=(
    # disable extra dependencies
    -DJAS_ENABLE_LIBHEIF=OFF

    -DJAS_ENABLE_DOC=OFF
    -DJAS_ENABLE_LATEX=OFF

    -DJAS_ENABLE_SHARED=OFF

    -DALLOW_IN_SOURCE_BUILD=ON
)

if is_darwin; then
    libs_args+=(
        # Make sure macOS's GLUT.framework is used, not XQuartz or freeglut
        # Reported to CMake upstream 4 Apr 2016 https://gitlab.kitware.com/cmake/cmake/issues/16045
        -DGLUT_glut_LIBRARY="'$(xcrun --show-sdk-path)/System/Library/Frameworks/GLUT.framework'"
    )
else
    libs_args+=(
        -DJAS_ENABLE_OPENGL=OFF
    )
fi

libs_build() {
    mkdir -p static && cd static

    cmake .. && make || return 1

    inspect make install &&

    pkgfile libjasper               \
            include/jasper          \
            lib/libjasper.a         \
            lib/pkgconfig/jasper.pc \
            &&

    cmdlet ./src/app/jiv     &&
    cmdlet ./src/app/jasper  &&
    cmdlet ./src/app/imginfo &&
    cmdlet ./src/app/imgcmp  &&

    check  jiv --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
