# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4

# Core application library for GNOME and GTK
# GLib is a general-purpose, portable utility pkginst, which provides many useful data types, macros, type conversions, string utilities, file utilities, a mainloop abstraction, and so on.
# shellcheck disable=SC2034
libs_lic=LGPLv2.1+
libs_ver=2.87.1
libs_url=https://github.com/GNOME/glib/archive/refs/tags/$libs_ver.tar.gz
libs_sha=263c8a370047cbc95451d60ca99bd8ff1991b88bc3470b8ab707f5e71d4c8996
libs_dep=( zlib pcre2 libiconv libffi )

libs_args=(
    # avoid hardcode PREFIX
    -Dlocalstatedir=/var
    -Druntime_dir=/var/run
    -Dgio_module_dir=/usr/lib/gio/modules   # OR set env GIO_MODULE_DIR

    # GLib libraries
    -Dglib_assert=true
    -Dglib_checks=true
    -Dglib_debug=enabled

    # Disable dtrace; see https://trac.macports.org/ticket/30413
    # and https://gitlab.gnome.org/GNOME/glib/-/issues/653
    -Ddtrace=disabled

    # no gobject-introspection
    #  => used to create language bindings for other programming languages like Python, JavaScript, Vala, and Lua.
    -Dintrospection=disabled

    -Dbsymbolic_functions=false

    -Dnls=disabled
    -Dsysprof=disabled
    -Dman-pages=disabled
    -Dtests=false
)

# GFileMonitor backend: auto, inotify, kqueue, libinotify-kqueue, win32
#is_linux && libs_args+=( -Dfile_monitor_backend=inotify ) || libs_args+=( -Dfile_monitor_backend=auto )

# shellcheck disable=SC2086
libs_build() {
    # no gvdb
    rm -rf subprojects/gvdb

    # ERROR: Dependency "iconv" not found
    sed -e "s/dependency('iconv')/dependency('iconv', required: true, static: true)/" \
        -i meson.build

    libs.requires iconv

    meson.setup

    meson.compile

    # TODO: update meson.build instead
    # Fix libiconv dependency
    sed -e '/Requires:/s/$/& libiconv/' \
        -i meson-private/glib-2.0.pc || die

    pkgfile libglib -- meson.install --tags devel

    # Fix missing libinotify.a
    if test -f "gio/inotify/libinotify.a"; then
        pkgconf libinotify.pc -linotify
        pkginst libinotify gio/inotify/libinotify.a libinotify.pc
    fi

    # gobject
    pkginst gobject bin                     \
        gobject/gobject-query               \
        gobject/glib-genmarshal             \
        gobject/glib-mkenums                \

    # gio
    pkginst gio bin                         \
        gio/gio                             \
        gio/gdbus                           \
        gio/gsettings                       \
        gio/gresource                       \
        gio/gio-querymodules                \
        gio/glib-compile-schemas            \
        gio/glib-compile-resources          \
        gio/gdbus-2.0/codegen/gdbus-codegen \

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
