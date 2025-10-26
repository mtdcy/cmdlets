# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4

# GLib is a general-purpose, portable utility pkginst, which provides many useful data types, macros, type conversions, string utilities, file utilities, a mainloop abstraction, and so on.

# shellcheck disable=SC2034
libs_lic="LGPL-2.1-or-later"
libs_ver=2.86.1
libs_url=https://github.com/GNOME/glib/archive/refs/tags/$libs_ver.tar.gz
libs_sha=c05a4ca8725ee81d41ae2f9c5be849243953d9c9df841ed31c1c31facaf88282
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
    -Dglib_debug=disabled
    -Dtests=False
)

libs_build() {
    rm -rf subprojects/gvdb
    mkdir -pv build

    meson setup build &&

    meson compile -C build --verbose || return 1

    pkgfile libglib -- meson install -C build --tags devel
}

# patch: fix meson install with DESTDIR and PREFIX

__END__
diff -ruN a/glib/meson.build b/glib/meson.build
--- a/glib/meson.build    2025-10-21 08:12:59
+++ b/glib/meson.build    2025-10-21 08:13:56
@@ -561,7 +561,7 @@

 # XXX: We add a leading './' because glib_libdir is an absolute path and we
 # need it to be a relative path so that join_paths appends it to the end.
-gdb_install_dir = join_paths(glib_datadir, 'gdb', 'auto-load', './' + glib_libdir)
+gdb_install_dir = join_paths(glib_datadir, 'gdb', 'auto-load')

 configure_file(
   input: 'libglib-gdb.py.in',
