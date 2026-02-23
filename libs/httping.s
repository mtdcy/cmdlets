# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
#
# Ping-like tool for HTTP requests

# fatal error: sys/socket.h: No such file or directory
#  depends on posix socket
libs_targets=( linux darwin )

# shellcheck disable=SC2034
libs_lic='AGPL'
libs_ver=4.4.0
libs_url=https://github.com/folkertvanheusden/HTTPing/archive/refs/tags/v4.4.0.tar.gz
libs_sha=87fa2da5ac83c4a0edf4086161815a632df38e1cc230e1e8a24a8114c09da8fd

libs_deps=( ncurses openssl )

# enable TCP Fast Open on macOS, upstream pr ref, https://github.com/folkertvanheusden/HTTPing/pull/48
is_darwin && libs_patches=(
    https://github.com/folkertvanheusden/HTTPing/commit/79236affb75667cf195f87a58faaebe619e7bfd4.patch?full_index=1
)

libs_args=(
    -DUSE_SSL=ON

    -DUSE_GETTEXT=OFF

    -DBUILD_SHARED_LIBS=OFF
)

libs_build() {
    # no gettext or intl
    sed -i main.c          \
        -e '/libintl.h/d'  \
        -e '/textdomain/d'

    cmake -S . -B build

    cmake --build build

    cmdlet ./build/httping

    check httping --version

    # macOS FIXME: SSL certificate validation failed: unable to get local issuer certificate
}

__END__

# SSL certificate validation failed: unable to get local issuer certificate
--- mssl.c.cafile	2025-02-16 16:54:15
+++ mssl.c	2026-02-22 14:17:59
@@ -300,6 +300,9 @@
 	meth = SSLv23_method();
 	ctx = SSL_CTX_new(meth);

+#if defined(__APPLE__)
+	SSL_CTX_load_verify_locations(ctx, "/etc/ssl/cert.pem", NULL);
+#else
 	if (ca_path == NULL)
 #if defined(__NetBSD__)
 		ca_path = "/etc/openssl/certs";
@@ -308,6 +311,7 @@
 #endif

 	SSL_CTX_load_verify_locations(ctx, NULL, ca_path);
+#endif

 #ifdef SSL_OP_NO_COMPRESSION
 	if (!ask_compression)
