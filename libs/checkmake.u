# Linter/analyzer for Makefiles

# shellcheck disable=SC2034
upkg_name=checkmake
upkg_lic="MIT"
upkg_ver=0.2.2
upkg_url=https://github.com/checkmake/checkmake/archive/refs/tags/$upkg_ver.tar.gz
upkg_zip=$upkg_name-$upkg_ver.tar.gz
upkg_sha=4e5914f1ee3e5f384d605406f30799bf556a06b9785d5b0e555fd88b43daf19c

# configure args
upkg_args=(
)

upkg_static() {
    go clean || true

    go build . &&

    cmdlet checkmake &&

    check checkmake
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4

