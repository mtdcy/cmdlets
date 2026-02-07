# Graphics library to dynamically manipulate images
#
# shellcheck disable=SC2034
libs_lic="GD"
libs_ver=2.3.3
libs_url=https://github.com/libgd/libgd/releases/download/gd-$libs_ver/libgd-$libs_ver.tar.xz
libs_sha=3fe822ece20796060af63b7c60acb151e5844204d289da0ce08f8fdf131e5a61
# mandatory
libs_dep=( libiconv )
# optional
libs_dep+=( zlib freetype libjpeg-turbo libpng libtiff libwebp libheif )

# revert breaking changes in 2.3.3, remove in next release
libs_patches=(
    https://github.com/libgd/libgd/commit/f4bc1f5c26925548662946ed7cfa473c190a104a.patch?full_index=1
)

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --without-avif
    --without-fontconfig
    --without-x
    --without-xpm

    # static only
    --disable-shared
    --enable-static
)

# optionals
is_listed zlib          "${libs_dep[@]}" && libs_args+=( --with-zlib        ) || libs_args+=( --without-zlib        )
is_listed freetype      "${libs_dep[@]}" && libs_args+=( --with-freetype    ) || libs_args+=( --without-freetype    )
is_listed fontconfig    "${libs_dep[@]}" && libs_args+=( --with-fontconfig  ) || libs_args+=( --without-fontconfig  )
is_listed libjpeg-turbo "${libs_dep[@]}" && libs_args+=( --with-jpeg        ) || libs_args+=( --without-jpeg        )
is_listed libpng        "${libs_dep[@]}" && libs_args+=( --with-png         ) || libs_args+=( --without-png         )
is_listed libtiff       "${libs_dep[@]}" && libs_args+=( --with-tiff        ) || libs_args+=( --without-tiff        )
is_listed libwebp       "${libs_dep[@]}" && libs_args+=( --with-webp        ) || libs_args+=( --without-webp        )
is_listed libheif       "${libs_dep[@]}" && libs_args+=( --with-heif        ) || libs_args+=( --without-heif        )

libs_build() {
    configure

    make

    pkgfile "$libs_name" -- make install bin_PROGRAMS=
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
