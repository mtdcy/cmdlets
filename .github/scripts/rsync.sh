#!/bin/bash -e
#
# rsync.sh source destination

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

info "rsync to $*"

source="$1"
IFS='@:' read -r user host port dest <<< "$2"

if test -n "$CMDLET_ARTIFACTS_TOKEN"; then
    echo "$CMDLET_ARTIFACTS_TOKEN" > .ssh_token
fi

remote="$user@$host:$dest"

ssh_opt=(-p "$port" -o StrictHostKeyChecking=no)

if test -f .ssh_token; then
    chmod 0600 .ssh_token
    ssh_opt+=(-i .ssh_token)
fi

opts=(
    -avz
    # 忽略顶层和第二层的{bin,lib,libexec,include,share}
    --exclude="/bin/"
    --exclude="/lib/"
    --exclude="/libexec/"
    --exclude="/include/"
    --exclude="/share/"
    --exclude="/*/bin/"
    --exclude="/*/lib/"
    --exclude="/*/libexec/"
    --exclude="/*/include/"
    --exclude="/*/share/"
    # 忽略隐藏文件
    --exclude=".*"
    -e "ssh ${ssh_opt[*]}"
    # no delete here
)

info "*** rsync $source => remote:$dest ***"
rsync "${opts[@]}" "$source" "$remote"

exit $?
