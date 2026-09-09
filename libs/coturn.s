# Free open source implementation of TURN and STUN Server

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=4.18.0
libs_rev=1
libs_url=https://github.com/coturn/coturn/archive/refs/tags/4.18.0.tar.gz
libs_sha=28d55294ac596fbd129b293a85e7bb1c5dc4bd15b7fb55c500f355149e5f4e28
libs_dep=( hiredis libevent sqlite openssl )

libs_args=(
    --localstatedir=/var
    --includedir="'$PREFIX/include'"

    --disable-debug
    --disable-rpath
)

libs_build() {
    export SSL_CFLAGS="$($PKG_CONFIG --cflags openssl)"
    export SSL_LIBS="$($PKG_CONFIG --libs openssl)"

    # coturn use PKGCONFIG instead of PKG_CONFIG
    export PKGCONFIG="$PKG_CONFIG"

    # no systemd
    export TURN_NO_SYSTEMD=1

    # user database:
    export TURN_NO_PQ=1
    export TURN_NO_MYSQL=1
    #export TURN_NO_SQLITE=1
    export TURN_NO_MONGO=1

    configure

    # fix cp: setting attributes for 'xxx': Not supported
    #  => ACL or docker's problem?
    sed -i Makefile \
        -e 's/cp -pf/cp -f/g'

    make

    cmdlet.install bin/turnserver turnserver turnadmin

    for x in bin/turnutils_*; do
        cmdlet.install "$x"
    done

    cmdlet.verify -- turnserver --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
