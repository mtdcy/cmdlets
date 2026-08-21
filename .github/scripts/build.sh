#!/bin/bash -ex

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

info "build $*"

pwd -P
bash --version
env

export CMDLET_LOGGING=silent
export CMDLET_NJOBS="${CMDLET_NJOBS:-1}"

# need to run configure as root
export FORCE_UNSAFE_CONFIGURE=1

unset TAG

if which brew; then
    _gnubin=(coreutils gnu-sed gawk grep gnu-tar findutils)
    for x in "${_gnubin[@]}"; do
        export PATH="$(brew --prefix "$x")/libexec/gnubin:$PATH"
    done
    unset _gnubin
fi

# make prepare-host fails on macos-15-intel
test -n "$BUILDER_NAME" || make prepare-host || true

TAG="$(bash libs.sh target)"

cmdlets=()
if test -n "$1"; then
    IFS=', ' read -r -a cmdlets <<< "$*"
else
    for x in $(bash libs.sh _target_ls_changed); do
        bash libs.sh _pkgfile_ready "$x" || cmdlets+=("$x")
    done
fi

ret=0

if [[ "$cmdlets" =~ -$ ]]; then
    export CMDLET_PKGFILES=0
    bash libs.sh build "${cmdlets[@]%-}" || ret=$?
elif [[ "$cmdlets" =~ \+$ ]]; then
    export CMDLET_CHECK=1
    bash libs.sh build "${cmdlets[@]%+}" || ret=$?
else
    bash libs.sh build "${cmdlets[@]}" || ret=$?
fi

# for release actions
bash libs.sh zip_files || true

# mingw32 is not ready => alway tag to HEAD
if [ "$ret" -eq 0 ] || [ "$TAG" = "x86_64-w64-mingw32" ]; then
    bash libs.sh maketag
elif [ -n "$CMDLET_WEBHOOK" ]; then
    text="Build cmdlets (${cmdlets[*]}) failed
---
$(git show HEAD --stat)
"

    curl --fail -sL --form-string "text=$text" "$CMDLET_WEBHOOK"
fi

exit "$ret"
