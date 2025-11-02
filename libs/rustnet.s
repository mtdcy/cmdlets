# A cross-platform network monitoring terminal UI tool built with Rust.

# shellcheck disable=SC2034
libs_lic=Apache-2.0
libs_ver=0.15.0
libs_url=https://github.com/domcyrus/rustnet/archive/refs/tags/v0.15.0.tar.gz
libs_sha=9fa251bbce11c4ff6f58ba57e08efbec94b2a031cd3d102d2ce45f0611d4f42e

# macOS: use system libpcap
is_linux && libs_dep=( libpcap elfutils )

# no eBPF for macOS
#  FIXME: enable eBPF brokes rustnet build when building for target
#   some code messup the rustflags or rustc-link-path, cause -lelf fails => **fuck fucking fucker**
#
#  FIXME: cargo build --target: some dependencies are not built for specified target
#is_darwin && libs_args=( --no-default-features )
libs_args=( --no-default-features ) # no eBPF

libs_build() {
    ## libbpf-sys: link static libraries
    #LIBBPF_SYS_LIBRARY_PATH="-L native=$PREFIX/lib"
    #LIBBPF_SYS_EXTRA_CFLAGS="$($PKG_CONFIG --cflags --libs libelf libpcap)"

    # native libpcap
    LIBPCAP_LIBDIR="-L native=$PREFIX/lib"

   #sed -i build.rs \
   #    -e "/Ok(())/{
   #            i println!(\"cargo:rustc-link-search=native=$PREFIX/lib\");
   #            i println!(\"cargo:rustc-link-lib=argp\");
   #            i println!(\"cargo:rustc-link-lib=fts\");
   #            i println!(\"cargo:rustc-link-lib=obstack\");
   #        }"

    cargo.setup

    echo "$RUSTFLAGS"

    cargo.build

    cmdlet.install "$(find target -name $libs_name)"

    cmdlet.check "$libs_name"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
