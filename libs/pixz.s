# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
# shellcheck disable=SC2034
libs_desc="Parallel, indexed, xz compressor"
libs_lic='BSD-2-Clause'
libs_ver=1.0.7
libs_url=(
    https://github.com/vasi/pixz/releases/download/v$libs_ver/pixz-$libs_ver.tar.gz
)
libs_sha=d1b6de1c0399e54cbd18321b8091bbffef6d209ec136d4466f398689f62c3b5f
libs_dep=( libarchive  xz libxslt )

libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking

)

libs_build() {
    configure

    make

    cmdlet.install src/pixz

    cmdlet.check pixz

    caveats << EOF
static built pixz @ $libs_ver

Usage:
    tar -I pixz -xf archive.tar.xz -C /tmp
    tar -I pixz -cf archive.tar.xz -C /opt
EOF
}

__END__
--- a/src/cpu.c   2026-02-15 09:07:57.270156784 +0800
+++ b/src/cpu.c   2026-02-15 09:09:05.617752924 +0800
@@ -1,5 +1,15 @@
+#if defined(_WIN32)
+#include <windows.h>
+
+size_t num_threads(void) {
+    SYSTEM_INFO sysinfo;
+    GetSystemInfo(&sysinfo);
+    int numCPU = sysinfo.dwNumberOfProcessors;
+}
+#else
 #include <unistd.h>

 size_t num_threads(void) {
     return sysconf(_SC_NPROCESSORS_ONLN);
 }
+#endif
