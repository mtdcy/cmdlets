#!/bin/bash -e

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

export CL_LOGGING="${CL_LOGGING:-silent}"

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
fi

#test -n "${cmdlets[*]}" || cmdlets=( $(bash libs.sh _deps_get ALL) )
test -n "${cmdlets[*]}" || {
    info "*** no cmdlets, exit ***"
    exit 0
}

[[ "${cmdlets[*]}" =~ ALL ]] && cmdlets=( $(bash libs.sh _deps_get ALL) ) || true

info "*** prepare ${cmdlets[*]} ***"

if [[ "$cmdlets" =~ -$ ]]; then
    bash libs.sh fetch "${cmdlets%-}"
else
    bash libs.sh fetch "${cmdlets[@]}" $(bash libs.sh rdepends "${cmdlets[@]}")
fi
