# syntax=docker/dockerfile:1
FROM ubuntu:latest

ARG CMDLETS
ARG NJOBS
ARG UPKG_MIRROR

ARG ARTIFACTS_REMOTE_PATH
ARG ARTIFACTS_REMOTE_HOST
ARG ARTIFACTS_REMOTE_PORT=22
ARG ARTIFACTS_REMOTE_USER

USER buildbot
WORKDIR /cmdlets
COPY --chown=buildbot . /cmdlets

SHELL ["/bin/bash", "-c"]
RUN <<-EOS
    set -ex
    id -u

    export NJOBS=$NJOBS
    export UPKG_MIRROR=$UPKG_MIRROR
    export FORCE_UNSAFE_CONFIGURE=1

    cmdlets=(${CMDLETS//,/ })
    if [[ "$CMDLETS" =~ ALL ]]; then
        cmdlets=($(bash ulib.sh _deps_get ALL))
        export NJOBS=$(nproc)
    fi

    ret=0
    for x in "${cmdlets[@]}"; do
        bash ulib.sh build "$x" || ret=$?
    done

    if [ -n "$ARTIFACTS_REMOTE_HOST" ]; then
        remote="$ARTIFACTS_REMOTE_USER@$ARTIFACTS_REMOTE_HOST:$ARTIFACTS_REMOTE_PATH"
        opt=(-e "ssh -p $ARTIFACTS_REMOTE_PORT -i ssh_id_rsa -o StrictHostKeyChecking=no" -avc)
        chmod 0600 ssh_id_rsa
        echo "*** rsync artifacts to remote ***" &&
        rsync "${opt[@]}" --exclude='packages.lst' prebuilts/ $remote/cmdlets/latest/ || ret=$?
        echo "*** rsync logs to remote ***" &&
        rsync "${opt[@]}" logs/ $remote/cmdlets/logs/ || ret=$?
        echo "*** rsync packages to remote ***" &&
        rsync "${opt[@]}" packages/ $remote/packages/ || ret=$?
    fi

    # always exit with success when build ALL
    #   => continue build with other platforms
    [[ "$CMDLETS" =~ ALL ]] && exit 0 || exit $ret
EOS
