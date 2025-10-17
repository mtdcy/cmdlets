# Docker clients

# shellcheck disable=SC2034,SC2248
libs_ver=28.5.1
libs_url="https://github.com/docker/cli.git#v$libs_ver"

DOCKER_COMPOSE_VERSION=2.39.4
DOCKER_BUILDX_VERSION=0.29.0

libs_resources=(
    "https://github.com/docker/compose.git#v$DOCKER_COMPOSE_VERSION"
    "https://github.com/docker/buildx.git#v$DOCKER_BUILDX_VERSION"
)

libs_build() (
    # setup go modules path
    export GOPATH="$PWD"

    mkdir -pv src/github.com/docker
    ln -srfv cli src/github.com/docker/cli

    # Fix: date: invalid option -- 'j'
    export BUILDTIME="$(TZ=UTC date)"

    # borrow from homebrew
    is_darwin && export CGO_ENABLED=1 || true

    # docker cli
    (
        pushd cli

        # -X main.version not working for docker
        go_build -ldflags="'-X github.com/docker/cli/cli/version.Version=$libs_ver -X github.com/docker/cli/cli/version.GitCommit=$(git_version)'" -o ../docker github.com/docker/cli/cmd/docker
    ) &&

    # docker plugins
    ( 
        # docker compose
        pushd compose

        go_build -ldflags="'-X github.com/docker/compose/v2/internal.Version=$(git_version)'" -o ../docker-compose ./cmd
    ) &&

    (
        # docker buildx
        pushd buildx

        go_build -ldflags="'-X github.com/docker/buildx/version.Version=$(git_version)'" -o ../docker-buildx ./cmd/buildx
    ) &&

    # install versioned files
    cmdlet docker docker@${libs_ver%.*} docker &&

    cmdlet docker-compose docker-compose@${DOCKER_COMPOSE_VERSION%.*} docker-compose &&

    cmdlet docker-buildx docker-buildx@${DOCKER_BUILDX_VERSION%.*} docker-buildx &&

    check docker --version &&

    check docker-compose version &&

    check docker-buildx version
)

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
