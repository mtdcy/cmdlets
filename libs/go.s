# Build simple, secure, scalable systems with Go

# shellcheck disable=SC2034
libs_lic="BSD-3-Clause"
libs_ver=1.25.4
libs_url=https://go.dev/dl/go$libs_ver.src.tar.gz
libs_sha=160043b7f17b6d60b50369436917fda8d5034640ba39ae2431c6b95a889cc98c

libs_build() {
    _go_init

    # build go
    cd src &&
    slogcmd CC="$CC" CXX="$CXX" ./make.bash &&
    # FIXME: test fails
    #slogcmd GO_TEST_SHORT=1 ./run.bash --no-rebuild &&
    cd - || die "build go failed"

    # Remove useless files. <= homebrew
    # Breaks patchelf because folder contains weird debug/test files
    slogcmd rm -rfv src/debug/elf/testdata
    # Binaries built for an incompatible architecture
    slogcmd rm -rfv src/runtime/pprof/testdata
    # Remove testdata with binaries for non-native architectures.
    slogcmd rm -rfv src/debug/dwarf/testdata

    # Remove xxx.dir
    slogcmd find . -type d -name "*.dir" -exec rm -frv {} \; || true
    # Remove empty dirs
    slogcmd find . -type d -empty -exec rm -frv {} \; || true

    # install files manually
    mkdir -pv "$PREFIX/libexec"     &&
    cp -rf ./ "$PREFIX/libexec/go"  &&

    for x in bin/*; do
        ln -sfv "../libexec/go/$x" "$PREFIX/$x"
    done || die "install go files failed"

    # pack files
    pkgfile go bin/go* libexec/go

    check go version
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
