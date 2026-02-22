#!/bin/bash -ex

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

info "build $*"

pwd -P
bash --version

export CMDLET_LOGGING=silent
export CMDLET_CCACHE=0
export CMDLET_NJOBS="${CMDLET_NJOBS:-1}"

# need to run configure as root
export FORCE_UNSAFE_CONFIGURE=1

unset TAG

if which brew; then
    _gnubin=( coreutils gnu-sed gawk grep gnu-tar findutils )
    for x in "${_gnubin[@]}"; do
        export PATH="$(brew --prefix "$x")/libexec/gnubin:$PATH"
    done
    unset _gnubin
fi

# make prepare-host fails on macos-15-intel
test -n "$BUILDER_NAME" || make prepare-host || true

cmdlets=()
if test -n "$1"; then
    cmdlets=( "$1" ) # build single library manually
else
    TAG="$(bash libs.sh target)"

    IFS=' ' read -r -a cmdlets < <(bash libs.sh target.changed "$TAG")

    # build cmdlet and rdepends by default
    rdepends=1
fi

# default test target
#[ -n "${cmdlets[*]}" ] || cmdlets=(ALL)
test -n "${cmdlets[*]}" || {
    info "*** no cmdlets, exit ***"
    exit 0
}

ret=0

info "*** build cmdlets: ${cmdlets[*]} ***"

if [[ "$cmdlets" =~ -$ ]]; then
    export CMDLET_PKGFILES=0
    bash libs.sh build "${cmdlets[@]%-}" || ret=$?
elif [[ "$cmdlets" =~ \+$ ]] || test -n "$rdepends"; then
    export CMDLET_CHECK=1
    bash libs.sh build "${cmdlets[@]%+}" || ret=$?
else
    bash libs.sh build "${cmdlets[@]}" || ret=$?
fi

# for release actions
bash libs.sh zip_files || true

# 127: build cmdlets fails instead of rdepends
if test -n "$TAG" && [ "$ret" -eq 0 -o "$ret" -ne 127 ]; then
	git tag -a "$TAG" -m "$TAG" --force

    # push only if no local changes
    branch=$(git rev-parse --abbrev-ref HEAD)
    if git diff --quiet "$branch" "origin/$branch"; then
        git push origin "$TAG" --force
    fi
fi

if [ -n "$CL_NOTIFY" ] && [ "$ret" -ne 0 ]; then
    text="Build cmdlets (${cmdlets[*]}) failed
    ---
$(git show HEAD --stat)
"

    curl --fail -sL --form-string "text=$text" "$CL_NOTIFY"
fi

exit "$ret"
