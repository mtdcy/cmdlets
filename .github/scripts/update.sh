#!/bin/bash -e

export CMDLET_LOGGING=silent

commits="$(mktemp)"

trap 'rm -fv $commits' EXIT

true > "$commits"  # create empty file

for lib in libs/*.s; do
    IFS='/.' read -r _ lib _ <<< "$lib"

    # ignores
    [[ "$lib" =~ ^_ || "$lib" == ALL ]] && continue

    # update
    (
        . libs.sh
        _load "$lib"

        test -n "$libs_ver" || exit
        test -z "$libs_stable" || exit

        # version in url?
        echo "$libs_url" | grep -qF "$libs_ver" || exit

        trap 'git checkout libs/$lib.s' EXIT
        trap 'exit 1' INT # ctrl-c

        IFS='.-' read -r m n r _ <<< "$libs_ver"

        if test -n "$r"; then
            newver="$m.$n.$((r + 1))"
            bash libs.sh update "$lib" "$newver" || {
                test -z "$libs_stable_minor" || exit
                # try update minor version
                newver="$m.$((n + 1)).0"
                bash libs.sh update "$lib" "$newver" || exit
            }
        elif test -n "$n"; then
            newver="$m.$((n + 1))"
            bash libs.sh update "$lib" "$newver" || exit
        else
            exit
        fi
        echo "" # new line

        git add "libs/$lib.s"
        echo "updated $lib => $newver" >> "$commits"
    ) || true

    echo "" # new line
done

test -s "$commits" || exit 1

# find out reverse dependencies
IFS=' ' read -r -a libs < <(grep -oP "updated \K\S+" "$commits" | xargs)
IFS=' ' read -r -a rdepends < <(bash libs.sh rdepends "${libs[@]}")

if test -n "${rdepends[*]}"; then
    echo -e "\n---\n" >> "$commits"
    echo -e "rdepends:\n" >> "$commits"
    for dep in "${rdepends[@]}"; do
        read -r rev < <(grep -oP "libs_rev=\K\S+" "libs/$dep.s") || true
        if test -n "$rev"; then
            sed -i "s/libs_rev=.*$/libs_rev=$((rev + 1))/" "libs/$dep.s"
        else
            sed -i "/libs_ver/a libs_rev=1" "libs/$dep.s"
        fi
        echo "  updated $dep revision => ${rev:-1}" >> "$commits"

        git add "libs/$dep.s"
    done
fi

git status

git commit -F- << EOF
🤖 [bot] updated cmdlets versions

$(cat "$commits")
EOF
