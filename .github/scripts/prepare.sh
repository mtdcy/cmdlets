#!/bin/bash -e

info() {
    echo -e "🐳\\033[34m [$(date '+%Y/%m/%d %H:%M:%S')] $* \\033[0m" >&2
}

export CMDLET_LOGGING="${CMDLET_LOGGING:-silent}"

cmdlets=( "$@" )

[[ "${cmdlets[*]}" =~ ALL ]] && cmdlets=( $(bash libs.sh depends ALL) ) || true

info "*** $CMDLET_TARGET: prepare ${cmdlets[*]} ***"

if [[ "$cmdlets" =~ -$ ]]; then
    bash libs.sh fetch $(bash libs.sh depends "${cmdlets[@]%-}") "${cmdlets[@]%-}"
elif [[ "$cmdlets" =~ \+$ ]]; then
    bash libs.sh fetch "${cmdlets[@]%+}" $(bash libs.sh rdepends "${cmdlets[@]%+}")
else
    bash libs.sh fetch "${cmdlets[@]}"
fi
