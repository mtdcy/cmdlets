# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
# Realtime console network usage monitor

# shellcheck disable=SC2034
libs_lic='GPLv2+'
libs_ver=0.7.4
libs_url=https://www.roland-riegel.de/nload/nload-0.7.4.tar.gz
libs_sha=c1c051e7155e26243d569be5d99c744d8620e65fa8a7e05efcf84d01d9d469e5
libs_dep=( ncurses )

libs_args=(
    --disable-dependency-tracking
    --disable-silent-rules
    --disable-dependency-tracking
)

# Help old config scripts identify arm64 linux
is_linux && libs_args+=( --build=$(uname -m)-unknown-linux-gnu )

libs_build() {
    slogcmd ./run_autotools

    configure

    make.all

    cmdlet.install  src/nload

    cmdlet.check    nload
}

#1. Patching configure.in file to make configure compile on Mac OS.
#   https://github.com/macports/macports-ports/raw/refs/heads/master/net/nload/files/patch-configure.in.diff
#2. crash on F2 and garbage in adapter name, see https://sourceforge.net/p/nload/bugs/8/ reported on 2014-04-03
#   https://sourceforge.net/p/nload/bugs/_discuss/thread/c9b68d8e/4a65/attachment/devreader-bsd.cpp.patch
__END__
diff --git a/configure.in b/configure.in
index c6d9f43..d280df3 100644
--- a/configure.in
+++ b/configure.in
@@ -38,7 +38,7 @@ case $host_os in
 
         AC_CHECK_FUNCS([memset])
         ;;
-    *bsd*)
+    *darwin*)
         AC_DEFINE(HAVE_BSD, 1, [Define to 1 if your build target is BSD.])
         AM_CONDITIONAL(HAVE_BSD, true)
         
diff --git a/src/devreader-bsd.cpp b/src/devreader-bsd.cpp
index b542704..c063fd7 100644
--- a/src/devreader-bsd.cpp
+++ b/src/devreader-bsd.cpp
@@ -91,7 +91,7 @@ list<string> DevReaderBsd::findAllDevices()
         if(sdl->sdl_family != AF_LINK)
             continue;
         
-        interfaceNames.push_back(string(sdl->sdl_data));
+        interfaceNames.push_back(string(sdl->sdl_data).substr(0, sdl->sdl_nlen));
     }
 
     free(buf);
-- 
2.51.1
