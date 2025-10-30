# Library for large linear classification

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=2.49
libs_url=https://www.csie.ntu.edu.tw/~cjlin/liblinear/oldfiles/liblinear-2.49.tar.gz
libs_sha=166ca3c741b2207a74978cdb55077261be43b1e58e55f2b4c4f40e6ec1d8a347
libs_dep=( )

libs_args=(
)

libs_build() {

    make linear.o newton.o blas/blas.a

    slogcmd $AR rcv liblinear.a linear.o newton.o blas/blas.a
    slogcmd $RANLIB liblinear.a

    pkginst $libs_name                      \
            include     linear.h            \
            lib         liblinear.a         \

}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
