#!/bin/bash -e

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

info "build $*"

pwd -P
bash --version

export CMDLET_LOGGING="${CMDLET_LOGGING:-silent}"
export CL_CCACHE="${CL_CCACHE:-0}"
export CL_NJOBS="${CL_NJOBS:-1}"

# need to run configure as root
export FORCE_UNSAFE_CONFIGURE=1

if which brew; then
    _gnubin=( coreutils gnu-sed gawk grep gnu-tar findutils )
    for x in "${_gnubin[@]}"; do
        export PATH="$(brew --prefix "$x")/libexec/gnubin:$PATH"
    done
    unset _gnubin
fi

# make prepare-host fails on macos-15-intel
test -n "$BUILDER_NAME" || make prepare-host || true

# check packages artifacts
find packages || true

echo $PATH
env | grep "^CL_" | grep -v TOKEN

cmdlets=()
if test -n "$1"; then
    cmdlets=( "$1" ) # build single library manually
else
    while read -r line; do
        # file been deleted or renamed
        test -e "$line" || continue

        # only top dir
        [ "${line%/*}" = "libs" ] && line="${line#*/}" || continue

        # excludes
        [[ "$line" =~ ^[.@_] ]] || cmdlets+=( "${line%.s}" )
    done < <(git diff --name-only HEAD~1 HEAD | grep "^libs/.*\.s")

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
    export CMDLET_FORCE_BUILD=1
    bash libs.sh build "${cmdlets[@]%-}" || ret=$?
elif [[ "$cmdlets" =~ \+$ ]] || test -n "$rdepends"; then
    bash libs.sh dist "${cmdlets[@]%+}" || ret=$?
else
    bash libs.sh build "${cmdlets[@]}" || ret=$?
fi

# for release actions
bash libs.sh zip_files || true

if [ -n "$CL_NOTIFY" ] && [ "$ret" -ne 0 ]; then
    text="Build cmdlets (${cmdlets[*]}) failed
    ---
$(git show HEAD --stat)
"

    curl --fail -sL --form-string "text=$text" "$CL_NOTIFY"
fi

if [ "$ret" -eq 0 ]; then
    # update tags
    arch="$(bash libs.sh arch)"
    # tag to HEAD
    git tag -a "$arch" -m "$arch" --force
    git push origin "$arch" --force
fi

exit "$ret"
