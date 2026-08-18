#!/bin/bash

clean() {
    if [ "$(stat -c '%u' .git)" -ne "$(id -u)" ]; then
        echo "== restore ownership of project files"
        sudo chown "$(id -u):$(id -g)" . -R
    fi
}
trap clean EXIT

HOST_SSH_ID="$(test -f ~/.ssh/id_rsa && cat ~/.ssh/id_rsa || cat ~/.ssh/id_ed25519)"

opts=()

# supported vars:
#   LOCAL_MACHINE: ubuntu-latest
#   LOCAL_BUILDER: lcr.io/mtdcy/builder:ubuntu-22.04
test -f .vars && opts+=(--var-file .vars)   || true

opts+=(
    # bind won't work with self-host
    #--bind
    #--no-skip-checkout # or copy local files

    # remove after failure
    --rm

    # turn off --pull
    #--action-offline-mode

    --github-instance=git.mtdcy.top

    # for actions/upload-artifact
    --artifact-server-path ./artifacts

    # https://nektosact.com/usage/runners.html
    # https://github.com/catthehacker/docker_images
    # https://gitea.com/gitea/runner-images
    #  => gitea/runner-immages are based on catthehacker/ubuntu:act-*

    --platform ubuntu-latest=gitea/runner-images:ubuntu-latest
    --platform ubuntu-24.04=gitea/runner-images:ubuntu-24.04
    --platform ubuntu-22.04=gitea/runner-images:ubuntu-22.04
    --platform macos-latest=-self-hosted
    --platform macos-arm64=-self-hosted
    --platform macos-intel=-self-hosted

    # variables
    --var LOCAL_REGISTRY=lcr.io
    --var REGISTRY=lcr.io
    #--var REGISTRY=ghcr.io
    --var REGISTRY_USER=mtdcy
    --var TZ=Asia/Shanghai
    --var MIRRORS=http://mirrors.mtdcy.top
    --var NOTIFY_WEBHOOK=https://chanify.mtdcy.top/v1/sender/

    # secrets
    --secret READ_TOKEN=2e03656f87b0505d90127bfd642d89674ae41b9b
    --secret COMMIT_TOKEN=1181808ae757d52393f9d8647a794944a4a76fec
    --secret HOST_SSH_ID_RSA="$HOST_SSH_ID"
    --secret NOTIFY_TOKEN="CIDA68MGEiJBQUlFUE1aNjZJU043UTdORkdCVU1VVURPM1hDMllYNDNFIgkIAhoFR2l0ZWEqIkFGSEE0NVdWNzNRQTVWNEFENVM1Mks2QVlEVUdaTVVGTk0..cA70txWFOGLXTQkPSSl-kFUUS4Govbol_tiwHnfkCxI"
)

# rsync artifacts
opts+=(
    --var PUSH_REGISTRY=true
    --var ARTIFACTS_REMOTE_HOST=rsync.mtdcy.top
    --var ARTIFACTS_REMOTE_PORT=6015
    --var ARTIFACTS_REMOTE_USER=mtdcy
    --var ARTIFACTS_REMOTE_PATH=/volume2/public
    --secret ARTIFACTS_REMOTE_TOKEN="$HOST_SSH_ID"
)

act "${opts[@]}" "$@"
