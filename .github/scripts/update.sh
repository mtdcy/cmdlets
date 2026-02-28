#!/bin/bash -e

export CMDLET_LOGGING=silent

commits="$(mktemp)"

trap 'rm -fv $commits' EXIT

true > "$commits"  # create empty file

for libs in libs/*.s; do
    IFS='/.' read -r _ libs _ <<< "$libs"

    # ignores
    [[ "$libs" =~ ^_ || "$libs" == ALL ]] && continue

    # update
    (
        . libs.sh
        _load $libs

        test -n "$libs_ver" || exit
        test -z "$libs_stable" || exit

        # version in url?
        echo "$libs_url" | grep -qF "$libs_ver" || exit

        trap 'git checkout libs/$libs.s' EXIT

        IFS='.-' read -r m n r _ <<< "$libs_ver"

        if test -n "$r"; then
            newver="$m.$n.$((r+1))"
            bash libs.sh update "$libs" "$newver" || {
                test -z "$libs_stable_minor" || exit
                # try update minor version
                newver="$m.$((n+1)).0"
                bash libs.sh update "$libs" "$newver" || exit
            }
        elif test -n "$n"; then
            newver="$m.$((n+1))"
            bash libs.sh update "$libs" "$newver" || exit
        else
            exit
        fi

        git add "libs/$libs.s"
        echo "updated $libs => $newver" >> "$commits"
    ) || true
done

test -s "$commits" || exit 1

git status

git commit -F- <<EOF
[AutoUpdated] update libs

$(cat "$commits")
EOF
