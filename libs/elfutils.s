# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
#
# Libraries and utilities for handling ELF objects
#
# shellcheck disable=SC2034
libs_lic=GPLv2+,LGPLv2
libs_ver=0.194
libs_url=https://sourceware.org/elfutils/ftp/0.194/elfutils-0.194.tar.bz2
libs_sha=09e2ff033d39baa8b388a2d7fbc5390bfde99ae3b7c67c7daaf7433fbcf0f01e
libs_dep=( zlib bzip2 zstd xz )

# musl missing some glibc features
if is_musl; then
    libs_dep+=( libargp musl-fts musl-obstack )

    # patches from alpine
    # https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/main/elfutils
    libs_patches=(
        https://gitlab.alpinelinux.org/alpine/aports/-/raw/master/main/elfutils/fix-aarch64_fregs.patch
        https://gitlab.alpinelinux.org/alpine/aports/-/raw/master/main/elfutils/fix-uninitialized.patch
        https://gitlab.alpinelinux.org/alpine/aports/-/raw/master/main/elfutils/musl-macros.patch
        https://gitlab.alpinelinux.org/alpine/aports/-/raw/master/main/elfutils/musl-asm-ptrace-h.patch
    )

    # musl-legacy-error
    # https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/main/musl-legacy-error
    libs_resources=(
        https://gitlab.alpinelinux.org/alpine/aports/-/raw/master/main/musl-legacy-error/error.h
    )
fi

libs_args=(
    --disable-option-checking
    --disable-dependency-tracking
    --disable-silent-rules

    --with-zlib
    --with-zstd
    --with-lzma
    --with-bzlib

    --program-prefix=elfutils-

    --disable-libdebuginfod
    --disable-debuginfod
    --disable-werror

    # no these for static
    --disable-nls
    --disable-rpath

    # static only
    --enable-static
)

libs_build() {

    export CFLAGS+=" -D_GNU_SOURCE -Wno-error -Wno-null-dereference"

    #STATIC_LIBS=(
    #    "$PREFIX/lib/libargp.a"
    #    "$PREFIX/lib/libfts.a"
    #    "$PREFIX/lib/libobstack.a"
    #)

    ## ar all musl static libraries
    #sed -i libelf/Makefile.am \
    #    -e "/_LIBADD =/s%$%& ${STATIC_LIBS[*]}%g"

    autoreconf -fiv

    #test -f error.h && ln -sfv ../error.h libelf

    configure

    # build and install only static libraries
    make.all bin_PROGRAMS=

    # fix libelf.pc with musl libraries
    pkgconf config/libelf.pc -largp -lfts -lobstack

    pkgfile libelf -- make.install bin_PROGRAMS=
}

libs.depends is_linux

# patch: enable static build
__END__
From 5245a2d1f517458b36be87807baaa205aa8a4f50 Mon Sep 17 00:00:00 2001
From: Chen Fang <mtdcy@MacMini-M4.local>
Date: Sun, 2 Nov 2025 13:01:21 +0800
Subject: [PATCH] enable static build

---
 configure.ac         |  8 +++++---
 libasm/Makefile.am   | 11 ++++-------
 libdw/Makefile.am    | 12 ++++--------
 libdwelf/Makefile.am |  4 ++--
 libdwfl/Makefile.am  |  4 ++--
 libelf/Makefile.am   |  9 +++------
 src/Makefile.am      |  8 ++++----
 7 files changed, 24 insertions(+), 32 deletions(-)

diff --git a/configure.ac b/configure.ac
index 58e58af2..6ecabc11 100644
--- a/configure.ac
+++ b/configure.ac
@@ -445,8 +445,10 @@ AS_HELP_STRING([--enable-install-elfh],[install elf.h in include dir]),
                [install_elfh=$enableval], [install_elfh=no])
 AM_CONDITIONAL(INSTALL_ELFH, test "$install_elfh" = yes)

-AM_CONDITIONAL(BUILD_STATIC, [dnl
-test "$use_gprof" = yes -o "$use_gcov" = yes])
+AC_ARG_ENABLE([static],
+AS_HELP_STRING([--enable-static],[enable static build]),
+               [enable_static=yes], [enable_static=no])
+AM_CONDITIONAL(BUILD_STATIC, test "$enable_static" = yes)

 AC_ARG_ENABLE([tests-rpath],
 AS_HELP_STRING([--enable-tests-rpath],[build $ORIGIN-using rpath into tests]),
@@ -1061,7 +1063,7 @@ AC_MSG_NOTICE([
     libdebuginfod client support       : ${enable_libdebuginfod}
     Debuginfod server support          : ${enable_debuginfod}
     Default DEBUGINFOD_URLS            : ${default_debuginfod_urls}
-    Debuginfod RPM sig checking        : ${enable_debuginfod_ima_verification}
+    Debuginfod RPM sig checking        : ${enable_debuginfod_ima_verification}
     Default DEBUGINFOD_IMA_CERT_PATH   : ${default_debuginfod_ima_cert_path}
     ${program_prefix}stacktrace support              : ${enable_stacktrace}

diff --git a/libasm/Makefile.am b/libasm/Makefile.am
index 969db935..458ee257 100644
--- a/libasm/Makefile.am
+++ b/libasm/Makefile.am
@@ -54,7 +54,7 @@ libasm_a_SOURCES = asm_begin.c asm_abort.c asm_end.c asm_error.c \
 libasm_pic_a_SOURCES =
 am_libasm_pic_a_OBJECTS = $(libasm_a_SOURCES:.c=.os)

-libasm_so_DEPS = ../lib/libeu.a ../libebl/libebl_pic.a ../libelf/libelf.so ../libdw/libdw.so
+libasm_so_DEPS = ../lib/libeu.a ../libebl/libebl_pic.a ../libelf/libelf.a ../libdw/libdw.a
 libasm_so_LDLIBS = $(libasm_so_DEPS)
 if USE_LOCKS
 libasm_so_LDLIBS += -lpthread
@@ -71,16 +71,13 @@ libasm.so: $(srcdir)/libasm.map $(libasm_so_LIBS) $(libasm_so_DEPS)
 	@$(textrel_check)
 	$(AM_V_at)ln -fs $@ $@.$(VERSION)

-install: install-am libasm.so
+install: install-am
 	$(mkinstalldirs) $(DESTDIR)$(libdir)
-	$(INSTALL_PROGRAM) libasm.so $(DESTDIR)$(libdir)/libasm-$(PACKAGE_VERSION).so
-	ln -fs libasm-$(PACKAGE_VERSION).so $(DESTDIR)$(libdir)/libasm.so.$(VERSION)
-	ln -fs libasm.so.$(VERSION) $(DESTDIR)$(libdir)/libasm.so
+	$(INSTALL_PROGRAM) libasm.a $(DESTDIR)$(libdir)/libasm.a

 uninstall: uninstall-am
 	rm -f $(DESTDIR)$(libdir)/libasm-$(PACKAGE_VERSION).so
-	rm -f $(DESTDIR)$(libdir)/libasm.so.$(VERSION)
-	rm -f $(DESTDIR)$(libdir)/libasm.so
+	rm -f $(DESTDIR)$(libdir)/libasm.a
 	rmdir --ignore-fail-on-non-empty $(DESTDIR)$(includedir)/elfutils

 noinst_HEADERS = libasmP.h symbolhash.h
diff --git a/libdw/Makefile.am b/libdw/Makefile.am
index c98fe31f..799029c6 100644
--- a/libdw/Makefile.am
+++ b/libdw/Makefile.am
@@ -108,7 +108,7 @@ am_libdw_pic_a_OBJECTS = $(libdw_a_SOURCES:.c=.os)
 libdw_so_LIBS = ../libebl/libebl_pic.a ../backends/libebl_backends_pic.a \
 		../libcpu/libcpu_pic.a libdw_pic.a ../libdwelf/libdwelf_pic.a \
 		../libdwfl/libdwfl_pic.a ../libdwfl_stacktrace/libdwfl_stacktrace_pic.a
-libdw_so_DEPS = ../lib/libeu.a ../libelf/libelf.so
+libdw_so_DEPS = ../lib/libeu.a ../libelf/libelf.a
 libdw_so_LDLIBS = $(libdw_so_DEPS) -ldl -lz $(argp_LDADD) $(fts_LIBS) $(obstack_LIBS) $(zip_LIBS) -pthread
 libdw.so: $(srcdir)/libdw.map $(libdw_so_LIBS) $(libdw_so_DEPS)
 	$(AM_V_CCLD)$(LINK) $(dso_LDFLAGS) -o $@ \
@@ -120,16 +120,12 @@ libdw.so: $(srcdir)/libdw.map $(libdw_so_LIBS) $(libdw_so_DEPS)
 	@$(textrel_check)
 	$(AM_V_at)ln -fs $@ $@.$(VERSION)

-install: install-am libdw.so
+install: install-am
 	$(mkinstalldirs) $(DESTDIR)$(libdir)
-	$(INSTALL_PROGRAM) libdw.so $(DESTDIR)$(libdir)/libdw-$(PACKAGE_VERSION).so
-	ln -fs libdw-$(PACKAGE_VERSION).so $(DESTDIR)$(libdir)/libdw.so.$(VERSION)
-	ln -fs libdw.so.$(VERSION) $(DESTDIR)$(libdir)/libdw.so
+	$(INSTALL_PROGRAM) libdw.a $(DESTDIR)$(libdir)/libdw.a

 uninstall: uninstall-am
-	rm -f $(DESTDIR)$(libdir)/libdw-$(PACKAGE_VERSION).so
-	rm -f $(DESTDIR)$(libdir)/libdw.so.$(VERSION)
-	rm -f $(DESTDIR)$(libdir)/libdw.so
+	rm -f $(DESTDIR)$(libdir)/libdw.a
 	rmdir --ignore-fail-on-non-empty $(DESTDIR)$(includedir)/elfutils

 libdwfl_objects = $(shell cat ../libdwfl/libdwfl.manifest)
diff --git a/libdwelf/Makefile.am b/libdwelf/Makefile.am
index 5fb57379..3a1ac0ea 100644
--- a/libdwelf/Makefile.am
+++ b/libdwelf/Makefile.am
@@ -46,8 +46,8 @@ libdwelf_a_SOURCES = dwelf_elf_gnu_debuglink.c dwelf_dwarf_gnu_debugaltlink.c \

 libdwelf = $(libdw)

-libdw = ../libdw/libdw.so
-libelf = ../libelf/libelf.so
+libdw = ../libdw/libdw.a
+libelf = ../libelf/libelf.a
 libebl = ../libebl/libebl.a
 libeu = ../lib/libeu.a

diff --git a/libdwfl/Makefile.am b/libdwfl/Makefile.am
index 6ad5ba10..8d6b68c3 100644
--- a/libdwfl/Makefile.am
+++ b/libdwfl/Makefile.am
@@ -85,8 +85,8 @@ libdwfl_a_SOURCES += zstd.c
 endif

 libdwfl = $(libdw)
-libdw = ../libdw/libdw.so
-libelf = ../libelf/libelf.so
+libdw = ../libdw/libdw.a
+libelf = ../libelf/libelf.a
 libebl = ../libebl/libebl.a
 libeu = ../lib/libeu.a

diff --git a/libelf/Makefile.am b/libelf/Makefile.am
index 05484c12..c4cae408 100644
--- a/libelf/Makefile.am
+++ b/libelf/Makefile.am
@@ -125,16 +125,13 @@ libelf.so: $(srcdir)/libelf.map $(libelf_so_LIBS) $(libelf_so_DEPS)
 libeu_objects = $(shell cat ../lib/libeu.manifest)
 libelf_a_LIBADD = $(addprefix ../lib/,$(libeu_objects))

-install: install-am libelf.so
+install: install-am
 	$(mkinstalldirs) $(DESTDIR)$(libdir)
-	$(INSTALL_PROGRAM) libelf.so $(DESTDIR)$(libdir)/libelf-$(PACKAGE_VERSION).so
-	ln -fs libelf-$(PACKAGE_VERSION).so $(DESTDIR)$(libdir)/libelf.so.$(VERSION)
-	ln -fs libelf.so.$(VERSION) $(DESTDIR)$(libdir)/libelf.so
+	$(INSTALL_PROGRAM) libelf.a $(DESTDIR)$(libdir)/libelf.a

 uninstall: uninstall-am
 	rm -f $(DESTDIR)$(libdir)/libelf-$(PACKAGE_VERSION).so
-	rm -f $(DESTDIR)$(libdir)/libelf.so.$(VERSION)
-	rm -f $(DESTDIR)$(libdir)/libelf.so
+	rm -f $(DESTDIR)$(libdir)/libelf.a

 EXTRA_DIST = libelf.map

diff --git a/src/Makefile.am b/src/Makefile.am
index f041d458..92f4f9b0 100644
--- a/src/Makefile.am
+++ b/src/Makefile.am
@@ -75,11 +75,11 @@ else
 libdebuginfod =
 endif
 else
-libasm = ../libasm/libasm.so
-libdw = ../libdw/libdw.so
-libelf = ../libelf/libelf.so
+libasm = ../libasm/libasm.a
+libdw = ../libdw/libdw.a
+libelf = ../libelf/libelf.a
 if LIBDEBUGINFOD
-libdebuginfod = ../debuginfod/libdebuginfod.so
+libdebuginfod = ../debuginfod/libdebuginfod.a
 else
 libdebuginfod =
 endif
--
2.51.1
