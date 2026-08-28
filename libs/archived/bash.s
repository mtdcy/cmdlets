# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
# Bourne-Again SHell, a UNIX command interpreter
#
# HEAD version for feature inspection:
#   #1. DON'T use this version as default interpreter

# shellcheck disable=SC2034
libs_lic=GPLv3+
libs_ver=5.2.21
libs_url=(
    https://github.com/bminor/bash/archive/refs/tags/bash-$libs_ver.tar.gz
    https://ftpmirror.gnu.org/gnu/bash/bash-$libs_ver.tar.gz
)

libs_sha=c8e31bdc59b69aaffc5b36509905ba3e5cbb12747091d27b4b977f078560d5b8

libs_deps=( ncurses readline libiconv )

libs_resources=(
    # patches <= cygwin <= fedora project
    https://mirrors.tuna.tsinghua.edu.cn/cygwin/x86_64/release/bash/bash-5.2.21-1-src.tar.xz
)

libs_patches=(
    bash-5.2.21-1.src/bash-2.03-profile.patch
    bash-5.2.21-1.src/bash-2.05a-interpreter.patch
    bash-5.2.21-1.src/bash-2.05b-debuginfo.patch
    bash-5.2.21-1.src/bash-2.05b-pgrp_sync.patch
    bash-5.2.21-1.src/bash-3.2-ssh_source_bash.patch
    bash-5.2.21-1.src/bash-setlocale.patch
    bash-5.2.21-1.src/bash-4.2-rc2-logout.patch
    bash-5.2.21-1.src/bash-4.2-manpage_trap.patch
    bash-5.2.21-1.src/bash-4.1-broken_pipe.patch
    bash-5.2.21-1.src/bash-4.2-size_type.patch
    bash-5.2.21-1.src/bash-4.3-man-ulimit.patch
    bash-5.2.21-1.src/bash-4.3-noecho.patch
    bash-5.2.21-1.src/bash-4.3-memleak-lc_all.patch
    bash-5.2.21-1.src/bash-4.4-no-loadable-builtins.patch
    bash-5.2.21-1.src/bash-5.0-syslog-history.patch
)

if is_mingw; then
    libs_deps+=( msys2 )

    libs_resources+=(
        #https://mirrors.tuna.tsinghua.edu.cn/cygwin/x86_64/release/cygwin/cygwin-devel/cygwin-devel-3.6.6-1-x86_64.tar.xz
        # msys2 headers and runtime
        #https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-headers-13.0.0.r505.g7d006b2ea-1-any.pkg.tar.zst
        #https://mirror.msys2.org/msys/x86_64/msys2-runtime-devel-3.6.6-1-x86_64.pkg.tar.zst
        #https://mirror.msys2.org/msys/x86_64/msys2-runtime-3.6.6-1-x86_64.pkg.tar.zst
    )

    libs_patches+=(
        #bash-5.2.21-1.src/bash-5.2-cygwin.patch
    )
fi

libs_args=(
    --disable-option-checking

    --with-curses
    --enable-readline
    --without-installed-readline
    --without-included-gettext

    --disable-nls
    --without-libintl-prefix

    # https://github.com/robxu9/bash-static/blob/master/build.sh
    --without-bash-malloc
)

is_mingw || libs_args+=(
    # enable features for HEAD version
    --enable-alias
    --enable-alt-array-implementation
    --enable-arith-for-command
    --enable-array-variables
    --enable-brace-expansion
    --enable-casemod-attributes
    --enable-casemod-expansions
    --enable-command-timing
    --enable-cond-command
    --enable-cond-regexp
    --enable-coprocesses
    --enable-direxpand-default
    --enable-directory-stack
    --enable-dparen-arithmetic
    --enable-extended-glob
    --enable-extended-glob-default
    --enable-function-import
    --enable-glob-asciiranges-default
    --enable-help-builtin
    --enable-job-control
    --enable-multibyte
    --enable-net-redirections
    --enable-process-substitution
    --enable-progcomp
    --enable-select
    #--enalbe-prompt-string-decoding -> unrecognized
)

# fix 'error: cannot guess build type'
is_darwin || libs_args+=( --build="$(uname -m)-unknown-linux-gnu" )

libs_build() {

    # macOS defined this:
    #  refer to https://github.com/Homebrew/homebrew-core/blob/90c02007778049214b6c76120bb74ef702eec449/Formula/b/bash.rb
    # CFLAGS+=" -DSSH_SOURCE_BASHRC"

    # musl has strtoimax
    if is_musl; then
        # https://github.com/robxu9/bash-static/blob/master/custom/bash-musl-strtoimax-debian-1023053.patch
        sed -i 's/bash_cv_func_strtoimax =.*;/bash_cv_func_strtoimax = no;/' m4/strtoimax.m4
        autoconf -f
    elif is_mingw; then
        # mingw32-w64 also uses __CYGWIN__
        # __CYGWIN__ => __MSYS2__CYGWIN__
        #grep -Rwl __CYGWIN__ . | xargs sed -i 's/\<__CYGWIN__\>/__MSYS2__CYGWIN__/g'

        MSYS2ROOT="$PREFIX/share/cygwin"

        #export CC="$CC --sysroot=$MSYS2ROOT"

        #libs.requires --sysroot="$MSYS2ROOT"
        libs.requires -I$MSYS2ROOT/usr/include #-D__MSYS2__CYGWIN__

        #libs.requires -D__CYGWIN__

        libs.requires -L$MSYS2ROOT/usr/lib -lcygwin

        export CFLAGS_FOR_BUILD=

        # io.h: DNO_OLDNAMES => use internal getcwd.c
        libs.requires -DNO_OLDNAMES
    fi

    configure

    # bash do not work well for cross compile
    if is_mingw; then
        make EXEEXT= BASHEXT=.exe -j1
    else
        make
    fi

    # install
    cmdlet.install bash

    # check
    cmdlet.check bash --version
}

__END__
# fix build for host
--- Makefile.in.fix_host_build	2026-02-21 08:02:44.850480226 +0800
+++ Makefile.in	2026-02-21 17:12:03.674837532 +0800
@@ -103,7 +103,7 @@
 # force the type of the machine (like -M_MACHINE) into the flags.
 .c.o:
 	$(RM) $@
-	$(CC) $(CCFLAGS) -c $<
+	$(CC) $(CCFLAGS) -c -H $<
 
 EXEEXT = @EXEEXT@
 OBJEXT = @OBJEXT@
@@ -112,7 +112,7 @@
 VERSPROG = bashversion$(EXEEXT)
 VERSOBJ = bashversion.$(OBJEXT)
 
-Program = bash$(EXEEXT)
+Program = bash$(BASHEXT)
 Version = @BASHVERS@
 PatchLevel = `$(BUILD_DIR)/$(VERSPROG) -p`
 RELSTATUS = @RELSTATUS@
@@ -152,10 +152,10 @@
 
 SYSTEM_FLAGS = -DPROGRAM='"$(Program)"' -DCONF_HOSTTYPE='"$(Machine)"' -DCONF_OSTYPE='"$(OS)"' -DCONF_MACHTYPE='"$(MACHTYPE)"' -DCONF_VENDOR='"$(VENDOR)"' $(LOCALE_DEFS)
 
-BASE_CCFLAGS = $(SYSTEM_FLAGS) $(LOCAL_DEFS) \
+BASE_CCFLAGS = $(LOCAL_DEFS) \
 	  $(DEFS) $(LOCAL_CFLAGS) $(INCLUDES) $(STYLE_CFLAGS)
 
-CCFLAGS = $(ADDON_CFLAGS) $(BASE_CCFLAGS) ${PROFILE_FLAGS} $(CPPFLAGS) $(CFLAGS)
+CCFLAGS = $(ADDON_CFLAGS) $(SYSTEM_FLAGS) $(BASE_CCFLAGS) ${PROFILE_FLAGS} $(CPPFLAGS) $(CFLAGS)
 
 CCFLAGS_FOR_BUILD = $(BASE_CCFLAGS) $(CPPFLAGS_FOR_BUILD) $(CFLAGS_FOR_BUILD)
 
@@ -956,6 +956,8 @@
 		$(RM) parser-built y.tab.c y.tab.h ; \
 	fi
 
+supports: $(CREATED_SUPPORT) $(TESTS_SUPPORT)
+
 recho$(EXEEXT):		$(SUPPORT_SRC)recho.c
 	@$(CC_FOR_BUILD) $(CCFLAGS_FOR_BUILD) ${LDFLAGS_FOR_BUILD} -o $@ $(SUPPORT_SRC)recho.c ${LIBS_FOR_BUILD}
 
