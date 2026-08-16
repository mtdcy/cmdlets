#!/bin/bash -e

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

info "rsync to $*"

IFS='@:' read -r user host port dest <<< "$*"

if test -n "$CL_ARTIFACTS_TOKEN"; then
    echo "$CL_ARTIFACTS_TOKEN" > .ssh_token
    chmod 0600 .ssh_token
fi

remote="$user@$host:$dest"

ssh_opt=(-p "$port" -o StrictHostKeyChecking=no)

test -f .ssh_token && ssh_opt+=(-i .ssh_token)   || true

opts=(
    -avz
    --exclude='/bin/'
    --exclude='/lib/'
    --exclude='/libexec/'
    --exclude='/include/'
    --exclude='/share/'
    --exclude='/.*'
    -e "ssh ${ssh_opt[*]}"
    # no delete here
)

info "*** rsync artifacts ***"
rsync "${opts[@]}" prebuilts/ "$remote/cmdlets/latest/" || ret=$?

info "*** rsync logs ***"
rsync "${opts[@]}" logs/ "$remote/cmdlets/logs/" || ret=$?

#info "*** rsync packages ***"
#rsync "${opts[@]}" packages/ "$remote/packages/" || ret=$?

exit $?
