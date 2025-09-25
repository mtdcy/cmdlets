#!/bin/bash -e
# prepare.sh [cmdlet1,cmdlet2,...]

pwd -P
# chown -R buildbot:buildbot .

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
elif test -n "$MSYSTEM"; then
    chown -R buildbot:buildbot .
fi
echo "$PATH" | tee PATH

if test -n "$1"; then
    IFS=', ' read -r -a cmdlets <<< "$@"
else
    files=($(git show --pretty="" --name-only HEAD | grep -w "^libs")) || true
    for x in "${files[@]}"; do
        [[ "$x" =~ \.u$ ]] || continue
        x=$(basename "${x%.u}")
        [[ "$x" =~ ^\. ]] && continue  ## ignored files
        [[ "$x" =~ ^@  ]] && continue  ## ignored files
        [[ "$x" =~ ^_  ]] && continue  ## ignored files
        cmdlets+=("$x")
    done
    [ -n "${cmdlets[*]}" ] || cmdlets=(lz4)

    # always expand ALL
    [ "${cmdlets[*]}" = ALL ] && cmdlets=($(bash ulib.sh _deps_get ALL)) || true
fi

echo "${cmdlets[*]}" > .cmdlets
