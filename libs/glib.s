# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4

# Core application library for GNOME and GTK
# GLib is a general-purpose, portable utility pkginst, which provides many useful data types, macros, type conversions, string utilities, file utilities, a mainloop abstraction, and so on.

# patches are needed to build with mingw
libs_stable_minor=1

# shellcheck disable=SC2034
libs_lic=LGPLv2.1+
libs_ver=2.86.3
libs_url=https://github.com/GNOME/glib/archive/refs/tags/$libs_ver.tar.gz
libs_sha=ad0718637e4b91bbf4732e609cea8b06117bfcea8ddc036477bebf43939aab9f
libs_dep=( zlib pcre2 libiconv libffi libintl )

is_mingw && libs_dep+=( cppwinrt )

libs_args=(
    # GLib libraries
    -Dglib_assert=true
    -Dglib_checks=true

    # Disable dtrace; see https://trac.macports.org/ticket/30413
    # and https://gitlab.gnome.org/GNOME/glib/-/issues/653
    -Ddtrace=disabled
    -Dsystemtap=disabled    # requires dtrace

    # no gobject-introspection
    #  => used to create language bindings for other programming languages like Python, JavaScript, Vala, and Lua.
    -Dintrospection=disabled

    # disabled features
    -Dnls=disabled
    -Dselinux=disabled
    -Dsysprof=disabled
    -Dlibmount=disabled
    -Dman-pages=disabled
    -Dglib_debug=disabled
    -Dtests=false
)

# avoid hardcode PREFIX
is_mingw || libs_args+=(
    -Dlocalstatedir=/var
    -Druntime_dir=/var/run
    -Dgio_module_dir=/usr/lib/gio/modules   # OR set env GIO_MODULE_DIR
)

# https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-glib2/PKGBUILD
if is_mingw; then
    libs_args+=(
        -Dlibelf=disabled
        -Dfile_monitor_backend=win32
    )

    libs_patches=(
        https://gitlab.gnome.org/GNOME/glib/-/commit/7e69f88480a4bf8d9653efd0310c4c25390a0c8b.patch
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-glib2/0002-disable_glib_compile_schemas_warning.patch

        # cppwinrt is cpp project but glib defines gwin32 codes as c code.
        https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-glib2/0004-disable-explicit-ms-bitfields.patch
    )
fi

# GFileMonitor backend: auto, inotify, kqueue, libinotify-kqueue, win32
#is_linux && libs_args+=( -Dfile_monitor_backend=inotify ) || libs_args+=( -Dfile_monitor_backend=auto )

# shellcheck disable=SC2086
libs_build() {
    # ERROR: Subproject gvdb is buildable: NO
    rm -rf subprojects/gvdb

    # sed -i '/libintl_deps/d' glib/meson.build
    libs.requires iconv

    if is_mingw; then
        libs.requires libwinrt

    fi

    # stub libintl:
    # Dependency intl found: YES unknown (cached)
    # meson.build:2345:2: ERROR: Assert failed: libintl.type_name() == 'internal'
    #  => build fails after internal libintl installed
    sed -i '/assert(libintl.*internal.)/d' meson.build

    meson.setup

    meson.compile

    # TODO: update meson.build instead
    # Fix libiconv dependency
    #sed -e '/Requires:/s/$/& libiconv/' \
    #    -i meson-private/glib-2.0.pc || die
    pkgconf meson-private/glib-2.0.pc libiconv

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
