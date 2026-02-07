# Lock file during command
# shellcheck disable=SC2034

libs_lic=ISC
libs_ver=0.4.0
libs_url=https://github.com/discoteq/flock/releases/download/v0.4.0/flock-0.4.0.tar.xz
libs_sha=01bbd497d168e9b7306f06794c57602da0f61ebd463a3210d63c1d8a0513c5cc

libs_deps=()
libs_args=(
    --disable-option-checking
    --enable-silent-rules
    --disable-dependency-tracking
)

libs_build() {
    # error: format '%u' expects argument of type 'unsigned int', but argument 2 has type 'suseconds_t'
    is_darwin || export CFLAGS+=" -Wno-error=format"

    configure

    make flock

    cmdlet.install flock

    # visual verify
    check flock --version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
