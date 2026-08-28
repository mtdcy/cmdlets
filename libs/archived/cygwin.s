# Git + bash for windows

libs_targets=( windows )

# shellcheck disable=SC2034
libs_lic='Apache-2.0'
libs_ver=3.6.6-1
libs_url=https://mirrors.tuna.tsinghua.edu.cn/cygwin/x86_64/release/cygwin/cygwin-devel/cygwin-devel-3.6.6-1-$(uname -m).tar.xz
libs_sha=89afdf90c0bf23b126901ab2ea2dab7cb50730d45b5ea8225957ce0b60cd8e71

libs_deps=( )

libs_args=( )

libs_build() {
    cmdlet.pkgconf  libcygwin.pc -lcygwin

    cmdlet.pkginst cygwin share/cygwin/usr ./include ./lib
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
