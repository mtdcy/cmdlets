# Linter/analyzer for Makefiles

# shellcheck disable=SC2034
libs_name=checkmake
libs_lic="MIT"
libs_ver=0.2.2
libs_url=https://github.com/checkmake/checkmake/archive/refs/tags/$libs_ver.tar.gz
libs_zip=$libs_name-$libs_ver.tar.gz
libs_sha=4e5914f1ee3e5f384d605406f30799bf556a06b9785d5b0e555fd88b43daf19c

# configure args
libs_args=(
)

libs_build() {
    go clean || true

    go build . &&

    cmdlet checkmake &&

    check checkmake
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4

