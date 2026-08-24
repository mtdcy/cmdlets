# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4

# Core application library for GNOME and GTK
# GLib is a general-purpose, portable utility package, which provides many useful data types, macros, type conversions, string utilities, file utilities, a mainloop abstraction, and so on.

# patches are needed to build with mingw
libs_stable_minor=1

# shellcheck disable=SC2034
libs_lic=LGPLv2.1+
libs_ver=2.89.4
libs_rev=1
libs_url=https://download.gnome.org/sources/glib/${libs_ver%.*}/glib-$libs_ver.tar.xz
libs_rev=1
libs_sha=1cdbb799f558832e6f14b8337b5fd599c6918ab144977b55e05e00a5e2e84a2c

libs_deps=(zlib pcre2 libiconv libffi)

libs_args=(
    --wrap-mode=nodownload

    # GLib libraries
    -Dglib_assert=true
    -Dglib_checks=true
    -Dglib_debug=disabled

    # Disable dtrace; see https://trac.macports.org/ticket/30413
    # and https://gitlab.gnome.org/GNOME/glib/-/issues/653
    -Ddtrace=disabled
    -Dsystemtap=disabled    # requires dtrace

    # no gobject-introspection
    #  => used to create language bindings for other programming languages like Python, JavaScript, Vala, and Lua.
    -Dintrospection=disabled

    # disable intl, use proxy-libintl instead
    -Dnls=disabled

    # disabled features
    -Dxattr=false
    -Dselinux=disabled
    -Dsysprof=disabled
    -Dlibmount=disabled
    -Dman-pages=disabled
    -Dgtk_doc=false
    -Dtests=false
)

# https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-glib2/PKGBUILD
if is_mingw; then
    libs_args+=(
        -Dlibelf=disabled
        -Dfile_monitor_backend=win32
    )

    #libs_patches=(
    #    https://gitlab.gnome.org/GNOME/glib/-/commit/7e69f88480a4bf8d9653efd0310c4c25390a0c8b.patch
    #    https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-glib2/0002-disable_glib_compile_schemas_warning.patch

    #    # cppwinrt is cpp project but glib defines gwin32 codes as c code.
    #    https://github.com/msys2/MINGW-packages/raw/refs/heads/master/mingw-w64-glib2/0004-disable-explicit-ms-bitfields.patch
    #)
else
    # avoid hardcode PREFIX
    libs_args+=(
        -Dlocalstatedir=/var
        -Druntime_dir=/var/run
        -Dgio_module_dir=/dev/null # use env GIO_MODULE_DIR instead
    )
fi

# GFileMonitor backend: auto, inotify, kqueue, libinotify-kqueue, win32
#is_linux && libs_args+=( -Dfile_monitor_backend=inotify ) || libs_args+=( -Dfile_monitor_backend=auto )

# shellcheck disable=SC2086
libs_build() {
    libs.requires iconv

    # fix 'error: format string is not a string literal (potentially insecure)'
    # fix 'error: format string is not a string literal'
    export CFLAGS+=" -Wno-format-security -Wno-format-nonliteral"

    # stub libintl:
    # Dependency intl found: YES unknown (cached)
    # meson.build:2345:2: ERROR: Assert failed: libintl.type_name() == 'internal'
    #  => build fails after internal libintl installed
    #sed -i '/assert(libintl.*internal.)/d' meson.build
    sed -i '/^libintl = /s/\<intl\>/libintl0/' meson.build

    meson.setup

    meson.compile

    # TODO: update meson.build instead
    # Fix libiconv dependency
    #sed -e '/Requires:/s/$/& libiconv/' \
    #    -i meson-private/glib-2.0.pc || die
    cmdlet.pkgconf meson-private/glib-2.0.pc libiconv

    cmdlet.pkgfile libglib -- meson.install --tags devel

    # Fix missing libinotify.a
    if test -f "gio/inotify/libinotify.a"; then
        cmdlet.pkgconf libinotify.pc -linotify
        cmdlet.pkginst libinotify gio/inotify/libinotify.a libinotify.pc
    fi

    # gobject
    cmdlet.pkginst gobject bin \
        gobject/gobject-query \
        gobject/glib-genmarshal \
        gobject/glib-mkenums

    # gio
    cmdlet.pkginst gio bin \
        gio/gio \
        gio/gdbus \
        gio/gsettings \
        gio/gresource \
        gio/gio-querymodules \
        gio/glib-compile-schemas \
        gio/glib-compile-resources \
        gio/gdbus-2.0/codegen/gdbus-codegen

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
