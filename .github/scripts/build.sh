#!/bin/bash -e

pwd -P

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

[ -f PATH ] && export PATH="$(cat PATH)" || true
          
export CL_LOGGING=silent
export CL_MIRRORS="$(cat cl_mirrors)"
export CL_CCACHE=0
export CL_NJOBS=1

ret=0

IFS=', ' read -r -a cmdlets < .cmdlets
for x in "${cmdlets[@]}"; do
    info "*** build $x ***"
    bash ulib.sh build "$x" || ret=$?
done
    
bash ulib.sh dependent "${cmdlets[@]}" || ret=$?

if [ -f cl_artifacts ]; then
    IFS='@:' read -r user host port dest < cl_artifacts

    remote="$user@$host:$dest"
    ssh_opt=(-p "$port" -o StrictHostKeyChecking=no)
    if [ -f cl_ssh_token ]; then
        chmod 0600 cl_ssh_token
        ssh_opt+=(-i cl_ssh_token)
    fi

    info "*** rsync artifacts to remote ***"
    rsync -avc -e "ssh ${ssh_opt[*]}" prebuilts/ "$remote/cmdlets/latest/" || ret=$?

    info "*** rsync logs to remote ***"
    rsync -avc -e "ssh ${ssh_opt[*]}" logs/ "$remote/cmdlets/logs/" || ret=$?

    info "*** rsync packages to remote ***"
    rsync -avc -e "ssh ${ssh_opt[*]}" packages/ "$remote/packages/" || ret=$?
fi

if [ -f cl_notify ] && [ "$ret" -ne 0 ]; then
    text="Build cmdlets (${cmdlets[*]}) failed
    ---
$(git show HEAD --stat)
" 

    curl --fail -sL --form-string "text=$text" "$(cat cl_notify)"
fi

exit "$ret"
