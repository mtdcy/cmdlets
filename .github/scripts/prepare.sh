#!/bin/bash -e

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

export CL_LOGGING="${CL_LOGGING:-silent}"

cmdlets=()
if test -n "$*"; then
    IFS=', ' read -r -a cmdlets <<< "$*"
else
    while read -r line; do
        # file been deleted or renamed
        test -f "$line" || continue

        # no subdir
        [ "$(dirname "$line")" = "libs" ] || continue

        libs="$(basename "$line")"
        [[ "$libs" =~ ^[.@_] ]] || cmdlets+=( "${libs%.s}" )
    done < <(git diff --name-only HEAD~1 HEAD | grep "^libs/.*\.s")
fi

test -n "${cmdlets[*]}" || cmdlets=( $(bash libs.sh _deps_get ALL) )

[[ "${cmdlets[*]}" =~ ALL ]] && cmdlets=( $(bash libs.sh _deps_get ALL) )

bash libs.sh fetch "${cmdlets[@]}"
