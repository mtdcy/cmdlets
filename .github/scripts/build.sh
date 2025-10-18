#!/bin/bash -e

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

info "build $*"

pwd -P
bash --version
          
export CL_LOGGING="${CL_LOGGING:-silent}"
export CL_CCACHE="${CL_CCACHE:-0}"
export CL_NJOBS="${CL_NJOBS:-1}"

# need to run configure as root
export FORCE_UNSAFE_CONFIGURE=1

# fix: detected dubious ownership in repository
git config --global --add safe.directory '*'

if which brew; then
    _gnubin=( coreutils gnu-sed gawk grep gnu-tar findutils )
    for x in "${_gnubin[@]}"; do
        export PATH="$(brew --prefix "$x")/libexec/gnubin:$PATH"
    done
    unset _gnubin
fi

echo $PATH
env | grep "^CL_" | grep -v TOKEN

cmdlets=()
if test -n "$*"; then
    IFS=', ' read -r -a cmdlets <<< "$@"
else
    while read -r line; do
        # file been deleted or renamed
        test -f "$line" || continue
        libs="$(basename "$line")"
        [[ "$libs" =~ ^[.@_] ]] || cmdlets+=( "${libs%.s}" )
    done < <(git diff --name-only HEAD~1 HEAD | grep "^libs/.*\.s")
fi

# default test target
[ -n "${cmdlets[*]}" ] || cmdlets=(ALL)

ret=0

info "*** build cmdlets: ${cmdlets[*]} ***"

if [[ "${cmdlets[*]}" =~ =force ]]; then
    export CL_FORCE=1

    IFS=' ' read -r -a cmdlets <<< "${cmdlets[*]//=force/}"
fi
    
bash libs.sh build "${cmdlets[@]}" || ret=$?

unset CL_FORCE

# for release actions
bash libs.sh zip_files || true

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
#    IFS=' ' read -r -a deps <<< "$(bash libs.sh _deps_get "$ulib")"
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
#    IFS=' ' read -r -a dependents <<< "$(bash libs.sh _sort_by_depends "${dependents[@]}")"
#
#    info "*** build dependents: ${dependents[*]} ***"
#
#    bash libs.sh build "${dependents[@]}" || ret=$?
#fi

if [ -n "$CL_ARTIFACTS" ] && [ -n "$CL_ARTIFACTS_TOKEN" ]; then
    echo "$CL_ARTIFACTS_TOKEN" > .ssh_token
    chmod 0600 .ssh_token

    IFS='@:' read -r user host port dest <<< "$CL_ARTIFACTS"

    remote="$user@$host:$dest"
    ssh_opt=( -p "$port" -o StrictHostKeyChecking=no )
    [ -f .ssh_token ] && ssh_opt+=( -i .ssh_token ) || true

    info "*** rsync artifacts to $CL_ARTIFACTS ***"
    rsync -avc --exclude '.*.d' -e "ssh ${ssh_opt[*]}" prebuilts/ "$remote/cmdlets/latest/" || ret=$?

    info "*** rsync logs to $CL_ARTIFACTS ***"
    rsync -avc --exclude '.*.d' -e "ssh ${ssh_opt[*]}" logs/ "$remote/cmdlets/logs/" || ret=$?

    info "*** rsync packages to $CL_ARTIFACTS ***"
    rsync -avc --exclude '.*.d' -e "ssh ${ssh_opt[*]}" packages/ "$remote/packages/" || ret=$?
fi

if [ -n "$CL_NOTIFY" ] && [ "$ret" -ne 0 ]; then
    text="Build cmdlets (${cmdlets[*]}) failed
    ---
$(git show HEAD --stat)
" 

    curl --fail -sL --form-string "text=$text" "$CL_NOTIFY"
fi

exit "$ret"
