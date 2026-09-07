# Library for manipulating JPEG-2000 images

# shellcheck disable=SC2034
libs_ver=4.2.9
libs_url=https://github.com/jasper-software/jasper/releases/download/version-$libs_ver/jasper-$libs_ver.tar.gz
libs_sha=f71cf643937a5fcaedcfeb30a22ba406912948ad4413148214df280afc425454
libs_dep=(libjpeg-turbo)

# configure args
libs_args=(
    # disable extra dependencies
    -DJAS_ENABLE_LIBHEIF=OFF

    -DJAS_ENABLE_DOC=OFF
    -DJAS_ENABLE_LATEX=OFF

    -DJAS_ENABLE_SHARED=OFF

    # static
    -DBUILD_SHARED_LIBS=OFF

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
    cmake.setup

    cmake.build

    cmdlet.pkgfile libjasper -- cmake.install --component Unspecified

    # opengl
    if is_darwin; then
        cmdlet.install ./src/app/jiv
    fi

    cmdlet.install ./src/app/jasper
    cmdlet.install ./src/app/imginfo
    cmdlet.install ./src/app/imgcmp

    cmdlet.check jasper --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
