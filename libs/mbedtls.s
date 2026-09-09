# Light-weight cryptographic and SSL/TLS library

# shellcheck disable=SC2034
libs_stable=1
# mbedtls 接口变化较大，选择上一个稳定版本而非最新版本

libs_lic=Apache-2.0
libs_ver=3.6.7
libs_rev=1
libs_url=https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-$libs_ver/mbedtls-$libs_ver.tar.bz2
libs_sha=a7e8bcbec0e6f761b4af24f25677626b35f762f68eef79c08677a363212d11f6
libs_dep=()

libs_args=(
    -DUSE_STATIC_MBEDTLS_LIBRARY=ON
    -DUSE_SHARED_MBEDTLS_LIBRARY=OFF

    -DENABLE_PROGRAMS=OFF
)

libs_build() {
    # borrow from ubuntu/debian
    CONFIG_H=include/mbedtls/mbedtls_config.h
    cp $CONFIG_H $CONFIG_H.bak
    ./scripts/config.py set MBEDTLS_DEPRECATED_WARNING
    ./scripts/config.py set MBEDTLS_THREADING_C
    ./scripts/config.py set MBEDTLS_THREADING_PTHREAD
    ./scripts/config.py set MBEDTLS_CMAC_C
    ./scripts/config.py set MBEDTLS_SSL_DTLS_SRTP

    cmake.setup

    cmake.build

    cmdlet.pkgfile libmbedtls -- cmake.install
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
