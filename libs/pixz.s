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

    cmdlet ./src/pixz

    check pixz --version

    caveats << EOF
static built pixz @ $libs_ver

Usage:
    tar -I pixz -xf archive.tar.xz -C /tmp
    tar -I pixz -cf archive.tar.xz -C /opt
EOF
}
