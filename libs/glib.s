# GLib is a general-purpose, portable utility pkginst, which provides many useful data types, macros, type conversions, string utilities, file utilities, a mainloop abstraction, and so on.

# shellcheck disable=SC2034
libs_lic="LGPL-2.1-or-later"
libs_ver=2.86.0
libs_url=https://github.com/GNOME/glib/archive/refs/tags/$libs_ver.tar.gz
libs_sha=56aef5791f402fff73a2de0664e573c5d00ef8cb71405eb76b388f44c6d78927
libs_dep=( zlib pcre2 libiconv libffi )

libs_args=(
    -Dlocalstatedir=/var
    -Druntime_dir=/var/run
    -Dbsymbolic_functions=false
    #-Dgio_module_dir=#{HOMEBREW_PREFIX}/lib/gio/modules

    # Disable dtrace; see https://trac.macports.org/ticket/30413
    # and https://gitlab.gnome.org/GNOME/glib/-/issues/653
    -Ddtrace=false

    # no gobject-introspection
    -Dintrospection=disabled

    -Dnls=disabled
    -Dsysprof=disabled
    -Dman-pages=disabled
    -Dtests=False
)

libs_build() {
    rm -rf subprojects/gvdb
    mkdir -pv build

    meson setup build && 

    meson compile -C build --verbose || return 1

    pkgfile libglib -- meson install -C build
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
