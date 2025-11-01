# MariaDB Connector/C is used to connect applications developed in C/C++ to MariaDB and MySQL databases.

# shellcheck disable=SC2034
libs_lic='LGPLv2.1+'
libs_ver=3.4.7
libs_url=https://github.com/mariadb-corporation/mariadb-connector-c/archive/refs/tags/v3.4.7.tar.gz
libs_sha=cf81cd1c71c3199da9d2125aee840cb6083d43e1ea4c60c4be5045bfc7824eba
libs_dep=( zlib zstd krb5 curl openssl )

libs_args=(
    -DINSTALL_LIBDIR=lib
    -DINSTALL_MANDIR=share/man

    # zlib and zstd
    -DWITH_EXTERNAL_ZLIB=ON
    -DZSTD_ROOT_DIR="'$PREFIX'"

    -DWITH_MYSQLCOMPAT=ON

    -DWITH_DOCS=OFF
    -DWITH_UNIT_TESTS=OFF

    # static only
    -DBUILD_SHARED_LIBS=OFF
    -DBUILD_STATIC_LIBS=ON
)

libs_build() {
    # remove included libraries
    rm -rf external 

    # static plugins
    find plugins -name CMakeLists.txt -exec sed -i \
        -e 's/CONFIGURATIONS DYNAMIC.*/CONFIGURATIONS STATIC DYNAMIC OFF/' \
        -e 's/DEFAULT DYNAMIC.*/DEFAULT STATIC/' \
        {} +

    cmake.setup

    cmake.build

    pkgfile $libs_name -- cmake.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
