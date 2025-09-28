#!/bin/bash -e

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

info "build $*"

pwd -P
          
export CL_LOGGING=silent
export CL_CCACHE=0
export CL_NJOBS=1

# need to run configure as root
export FORCE_UNSAFE_CONFIGURE=1

# fix: detected dubious ownership in repository
git config --global --add safe.directory "$PWD"
          
if which brew; then
    make prepare-host

    brewprefix="$(brew --prefix)"
    export PATH="$brewprefix/opt/coreutils/libexec/gnubin:$PATH"
    export PATH="$brewprefix/opt/gnu-sed/libexec/gnubin:$PATH"
    export PATH="$brewprefix/opt/grep/libexec/gnubin:$PATH"
    export PATH="$brewprefix/opt/gnu-tar/libexec/gnubin:$PATH"
    export PATH="$brewprefix/opt/findutils/libexec/gnubin:$PATH"
fi

if test -n "$1"; then
    IFS=', ' read -r -a cmdlets <<< "$@"
else
    while read -r line; do
        IFS='/.' read -r _ ulib _ <<< "$line"
        [[ "$ulib" =~ ^\. ]] && continue  ## ignored files
        [[ "$ulib" =~ ^@  ]] && continue  ## ignored files
        [[ "$ulib" =~ ^_  ]] && continue  ## ignored files
        cmdlets+=( "$ulib" )
    done < <(git show --pretty="" --name-only HEAD | grep "^libs/.*\.u")

    [ -n "${cmdlets[*]}" ] || cmdlets=(unzip)
fi

# always expand ALL
if [ "${cmdlets[*]}" = ALL ]; then
    IFS=' ' read -r -a cmdlets <<< "$(bash ulib.sh _deps_get ALL)"
fi

ret=0

info "*** build cmdlets: ${cmdlets[*]} ***"

for cmdlet in "${cmdlets[@]}"; do
    IFS='=' read -r cmdlet force <<< "$cmdlet"
    [ -z "$force" ] || export CL_FORCE=1
    bash ulib.sh build "$cmdlet" || ret=$?
    unset CL_FORCE
done

## find out dependents
#dependents=()
#for pkg in libs/*.u; do
#    IFS='/.' read -r _ ulib _ <<< "$pkg"
#
#    [[ "$ulib" =~ ^@  ]] && continue
#    [[ "$ulib" == ALL ]] && continue
#
#    # already exists
#    [[ "${dependents[*]}" == *"$ulib"* ]] && continue
#
#    IFS=' ' read -r -a deps <<< "$(bash ulib.sh _deps_get "$ulib")"
#
#    for x in "${deps[@]}"; do
#        if [[ "${cmdlets[*]}" == *"$x"* ]]; then
#            dependents+=( "$ulib" )
#            break
#        fi
#    done
#done
#
#if [ -n "${dependents[*]}" ]; then 
#    IFS=' ' read -r -a dependents <<< "$(bash ulib.sh _sort_by_depends "${dependents[@]}")"
#
#    info "*** build dependents: ${dependents[*]} ***"
#
#    bash ulib.sh build "${dependents[@]}" || ret=$?
#fi

if [ -n "$CL_ARTIFACTS" ]; then
    if [ -n "$CL_SSH_TOKEN" ]; then
        echo "$CL_SSH_TOKEN" > .ssh_token
        chmod 0600 .ssh_token
    fi

    IFS='@:' read -r user host port dest <<< "$CL_ARTIFACTS"

    remote="$user@$host:$dest"
    ssh_opt=( -p "$port" -o StrictHostKeyChecking=no )
    [ -f .ssh_token ] && ssh_opt+=( -i .ssh_token ) || true

    info "*** rsync artifacts to remote ***"
    rsync -avc -e "ssh ${ssh_opt[*]}" prebuilts/ "$remote/cmdlets/latest/" || ret=$?

    info "*** rsync logs to remote ***"
    rsync -avc -e "ssh ${ssh_opt[*]}" logs/ "$remote/cmdlets/logs/" || ret=$?

    info "*** rsync packages to remote ***"
    rsync -avc -e "ssh ${ssh_opt[*]}" packages/ "$remote/packages/" || ret=$?
fi

if [ -n "$CL_NOTIFY" ] && [ "$ret" -ne 0 ]; then
    text="Build cmdlets (${cmdlets[*]}) failed
    ---
$(git show HEAD --stat)
" 

    curl --fail -sL --form-string "text=$text" "$CL_NOTIFY"
fi

exit "$ret"
