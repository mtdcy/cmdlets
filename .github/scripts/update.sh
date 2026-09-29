#!/bin/bash -e

export CMDLET_LOGGING=silent

commits="$(mktemp)"

trap 'rm -fv $commits' EXIT

mkdir -pv packages
true > "$commits"  # create empty file

cmdlets=()

while IFS='/' read -r _ libs _; do
    libs=${libs%.rules} # remove rules suffix

    # ignores
    [[ "$libs" == ALL ]] && continue

    cmdlets+=("$libs")
done < <(
    find libs -maxdepth 1 -type f -name "*.rules"
    find libs -maxdepth 2 -type f -name "RULES"
)

for libs in "${cmdlets[@]}"; do
    # ignores
    [[ "$libs" == ALL ]] && continue

    # update
    (   
        . libs.sh
        _load "$libs"

        test -n "$libs_ver" || exit
        test -z "$libs_stable" || exit

        # version in url?
        echo "$libs_url" | grep -qF "$libs_ver" || exit

        trap "git checkout $_LOAD_FILE" EXIT
        trap 'exit 1' INT # ctrl-c

        IFS='.-' read -r m n r _ <<< "$libs_ver"

        if test -n "$r"; then
            newver="$m.$n.$((r + 1))"
            bash libs.sh update "$libs" "$newver" || {
                test -z "$libs_stable_minor" || exit
                # try update minor version
                newver="$m.$((n + 1)).0"
                bash libs.sh update "$libs" "$newver" || exit
            }
        elif test -n "$n"; then
            newver="$m.$((n + 1))"
            bash libs.sh update "$libs" "$newver" || exit
        else
            exit
        fi
        echo "" # new line

        git add "$_LOAD_FILE"
        echo "updated $libs => $newver" >> "$commits"
    ) || true

    echo "" # new line
done

test -s "$commits" || exit 1

## find out reverse dependencies
#IFS=' ' read -r -a libs < <(grep -oP "updated \K\S+" "$commits" | xargs)
#IFS=' ' read -r -a rdepends < <(bash libs.sh rdepends "${libs[@]}")
#
#if test -n "${rdepends[*]}"; then
#    echo -e "\n---\n" >> "$commits"
#    echo -e "rdepends:\n" >> "$commits"
#    for dep in "${rdepends[@]}"; do
#        read -r rev < <(grep -oP "libs_rev=\K\S+" "libs/$dep.s" | head -n1) || true
#        sed -i "libs/$dep.s" \
#            -e '/^libs_rev=.*$/d' \
#            -e "/^libs_ver=/a libs_rev=$((rev + 1))"
#        echo "  updated $dep revision => ${rev:-1}" >> "$commits"
#
#        git add "libs/$dep.s"
#    done
#fi

git status

git commit -F- << EOF
🤖 [bot] updated cmdlets versions

$(cat "$commits")
EOF
