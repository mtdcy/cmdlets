# Round Robin Database

# shellcheck disable=SC2034
libs_lic='GPLv2'
libs_ver=1.9.0
libs_url=https://github.com/oetiker/rrdtool-1.x/releases/download/v1.9.0/rrdtool-1.9.0.tar.gz
libs_sha=5e65385e51f4a7c4b42aa09566396c20e7e1a0a30c272d569ed029a81656e56b
libs_dep=( glib libpng libxml2 )
# glib with g_regex => regex support

libs_patches=(
    # Fix -flat_namespace being used on Big Sur and later.
    https://raw.githubusercontent.com/Homebrew/homebrew-core/1cf441a0/Patches/libtool/configure-big_sur.diff
    # fix HAVE_DECL checks, upstream pr ref, https://github.com/oetiker/rrdtool-1.x/pull/1262
    https://github.com/oetiker/rrdtool-1.x/commit/98b2944d3b41f6e19b6a378d7959f569fdbaa9cd.patch?full_index=1
)

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

libs_build() {
    hack.configure

    configure

    make.all

    pkgfile librrd -- make.install bin_PROGRAMS=

    for x in rrdtool rrdupdate rrdcached; do
        cmdlet.install "./src/$x"
    done

    cmdlet.check rrdtool
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
