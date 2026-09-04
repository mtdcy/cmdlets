# Round Robin Database

# shellcheck disable=SC2034
libs_lic='GPLv2+'
libs_ver=1.11.0
libs_rev=3
libs_url=https://github.com/oetiker/rrdtool-1.x/releases/download/v1.11.0/rrdtool-1.11.0.tar.gz
libs_sha=24c345b5c077c1b2b2fcbc1a364f1da051650fb6743ad5213096adc04c862ed4

libs_deps=(glib libxml2)
# glib with g_regex => regex support

#libs_patches=(
#    # Fix -flat_namespace being used on Big Sur and later.
#    https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff
#    # fix HAVE_DECL checks, upstream pr ref, https://github.com/oetiker/rrdtool-1.x/pull/1262
#    https://github.com/oetiker/rrdtool-1.x/commit/98b2944d3b41f6e19b6a378d7959f569fdbaa9cd.patch?full_index=1
#)

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking

    # bindings
    --disable-lua
    --disable-perl
    --disable-python
    --disable-ruby
    --disable-tcl

    # options from ntopng
    --disable-libdbi
    --disable-libwrap
    --disable-librados

    --disable-rrdcgi
    --disable-rrd_graph

    # no these for static libraries
    --disable-nls
    --disable-docs
    --disable-rpath
    --disable-examples

    --disable-shared
    --enable-static
)

# configure: error: --enable-mmap requested but mmap() was not detected
is_mingw && libs_args+=(--disable-mmap --disable-rrdcached) || true

libs_build() {
    configure

    # fix libraries order
    #  1. place -llzma after -lxml2
    sed -i Makefile src/Makefile \
        -e '/^ALL_LIBS =/{
                s/ -llzma//g;
                s/-lxml2/& -llzma/;
            }'

    make.all

    # fix librrd.pc for static libraries
    pkgconf src/librrd.pc \
        $($PKG_CONFIG --cflags --libs glib-2.0 libpng) \
        $($PREFIX/bin/xml2-config --cflags --libs)

    pkgfile librrd -- make.install bin_PROGRAMS=

    for x in rrdtool rrdupdate; do
        cmdlet.install "./src/$x"
    done

    cmdlet.check rrdtool
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
