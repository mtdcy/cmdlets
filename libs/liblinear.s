# Library for large linear classification

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=2.50
libs_url=https://www.csie.ntu.edu.tw/~cjlin/liblinear/oldfiles/liblinear-2.50.tar.gz
libs_sha=e5eeafe2159c41148b59304da2ba0ed12648e3d491ce2b9625058e174e96ca29
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
