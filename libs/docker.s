# Docker clients

# shellcheck disable=SC2034,SC2248
libs_ver=28.5.1
libs_url=https://github.com/docker/cli/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=3872f03dd3d1e2769ecad57c8744743e72ad619f72f1897f4886fd44746337cd

libs_resources=(
    "https://github.com/docker/compose/archive/refs/tags/v2.40.1.tar.gz;1f6a066533f25ae61fac7b196c030d10693b8669f21f3798e738d70cea158853"
    "https://github.com/docker/buildx/archive/refs/tags/v0.29.1.tar.gz;20f62461257d3f20ac98c6e6d3f22ca676710644d9e4688c2e4c082bfba9b619"
)

libs_build() (
    # setup go modules path
    export GOPATH="$PWD"

    # Fix: date: invalid option -- 'j'
    export BUILDTIME="$(TZ=UTC date)"

    # borrow from homebrew
    is_darwin && export CGO_ENABLED=1 || true

    mkdir -pv src/github.com/docker
    ln -srfv . src/github.com/docker/cli

    # -X main.version not working for docker
    go_build -ldflags="'-X github.com/docker/cli/cli/version.Version=$libs_ver -X github.com/docker/cli/cli/version.GitCommit=$(git_version)'" -o docker github.com/docker/cli/cmd/docker &&

    # docker plugins
    (
        # docker compose
        pushd compose-*

        go_build -ldflags="'-X github.com/docker/compose/v2/internal.Version=$(git_version)'" -o ../docker-compose ./cmd
    ) &&

    (
        # docker buildx
        pushd buildx-*

        go_build -ldflags="'-X github.com/docker/buildx/version.Version=$(git_version)'" -o ../docker-buildx ./cmd/buildx
    ) &&

    # install tools
    cmdlet docker                          &&
    cmdlet docker-compose                  &&
    cmdlet docker-buildx                   &&
    # install all tools as one pkgfile
    pkgfile docker bin/docker bin/docker-* &&

    check docker-compose version           &&
    check docker-buildx version            &&
    check docker --version
)

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
