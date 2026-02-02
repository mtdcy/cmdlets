# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4

# GLib is a general-purpose, portable utility pkginst, which provides many useful data types, macros, type conversions, string utilities, file utilities, a mainloop abstraction, and so on.

# shellcheck disable=SC2034
libs_lic="LGPL-2.1-or-later"
libs_ver=2.86.3
libs_url=https://github.com/GNOME/glib/archive/refs/tags/$libs_ver.tar.gz
libs_sha=ad0718637e4b91bbf4732e609cea8b06117bfcea8ddc036477bebf43939aab9f
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
    -Dtests=false
)

libs_build() {
    # no gvdb
    rm -rf subprojects/gvdb

    meson.setup

    meson.compile

    pkgfile libglib -- meson.install #--tags devel

    for x in glib-genmarshal glib-mkenums; do
        cmdlet.install "./build/gobject/$x"
    done

    for x in glib-compile-resources glib-compile-schemas; do
        cmdlet.install "./build/gio/$x"
    done
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
