# hping3 is a network tool able to send custom TCP/IP packets

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4

# shellcheck disable=SC2034
libs_ver=3.0.0-alpha-2
libs_url=https://mirrors.wikimedia.org/ubuntu/pool/universe/h/hping3/hping3_3.a2.ds2.orig.tar.gz
libs_sha=be027ed1bc1ebebd2a91c48936493024c3895e789c8490830e273ee7fe6fc09d
libs_dep=( libpcap )

libs_resources=(
    https://mirrors.wikimedia.org/ubuntu/pool/universe/h/hping3/hping3_3.a2.ds2-10build2.debian.tar.xz
)

libs_patches=(
    debian/patches/010_install.diff
    debian/patches/020_libpcap0.8.diff
    debian/patches/030_bytesex.diff
    debian/patches/040_spelling.diff
    debian/patches/050_personality.diff
    debian/patches/060_version.diff
    debian/patches/070_tcl.diff
    debian/patches/080_ip_id_field.diff
    debian/patches/090_fr_manpage.diff
    debian/patches/100_hyphen_used_as_minus_sign.diff
    debian/patches/110_dontfrag_offbyone.diff
    debian/patches/120_rtt_icmp_unreachable.diff
    debian/patches/130_spelling_error_in_binary.diff
    debian/patches/140_data_size_udp.diff
    debian/patches/150_gnu_kfreebsd.diff
    debian/patches/160_tcp_mss.diff
    debian/patches/170_gnu_hurd.diff
    debian/patches/180_dpkg-buildflags.diff
    debian/patches/190_ip_optlen_conflicting_types.diff
    debian/patches/fix_icmp_ipid.patch
    debian/patches/191_fix_ftbfs_with_gcc10.patch
)

libs_args=(
)

libs_build() {
    libs.requires.c89

    if is_darwin; then
        grep "defined OSTYPE_FREEBSD" . -Rl | xargs sed -i 's/defined OSTYPE_FREEBSD/& || defined OSTYPE_DARWIN/g'
        sed -i '/pcap.h/i #include <net/bpf.h>' libpcap_stuff.c
        sed -i 's%endian.h%machine/endian.h%'   bytesex.h
    fi

    slogcmd ./configure --no-tcl

    make CCOPT=

    cmdlet ./hping3

    check hping3 --version
}

# patches from macport
__END__
--- a/gethostname.c	2014-05-29 13:20:06.000000000 -0400
+++ b/gethostname.c	2014-05-29 13:19:42.000000000 -0400
@@ -18,7 +18,16 @@
 #include <arpa/inet.h>
 #include <string.h>

+#ifndef strlcpy
+/*
+ * On OS X (and probably some other systems aswell), strlcpy might be
+ * implemented as a macro. If this macro is defined while we're including this
+ * header, strlcpy is already declared and trying to re-declare it with the
+ * following line *will* fail, because the macro will expand to something
+ * that's not a valid function name.
+ */
 size_t strlcpy(char *dst, const char *src, size_t siz);
+#endif /* !defined(strlcpy) */

 char *get_hostname(char* addr)
 {
