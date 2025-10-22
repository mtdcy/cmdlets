# A syntax-highlighting pager for git, diff, grep, and blame output

# shellcheck disable=SC2034
libs_desc="A syntax-highlighting pager for git, diff, grep, and blame output"

libs_lic='MIT'
libs_ver=0.18.2
libs_url=https://github.com/dandavison/delta/archive/refs/tags/$libs_ver.tar.gz
libs_sha=64717c3b3335b44a252b8e99713e080cbf7944308b96252bc175317b10004f02
libs_dep=( zlib libgit2 ) # oniguruma

libs_patches=(
    # support libgit2 1.9, https://github.com/dandavison/delta/pull/1930
    https://github.com/dandavison/delta/commit/9d6101e82a79daecfa9e81fa54c440b2e0442a33.patch?full_index=1
)

libs_args=(
    --release
    --verbose
)

libs_build() {
    # use libgit2 in PREFIX
    export LIBGIT2_NO_VENDOR=1

    # use static libonig in PREFIX => cargo build fails the first time
    #export RUSTONIG_SYSTEM_LIBONIG=1
    #export LIBONIG_STATIC=1
    #export RUSTONIG_STATIC_LIBONIG=1 # => fails

    cargo build

    cmdlet "$(find target -name delta)"

    check delta --version

    caveats <<EOF
delta @ $libs_ver

Usage:

git config --global core.pager delta
git config --global interactive.diffFilter 'delta --color-only'
git config --global merge.conflictStyle zdiff3

# delta options
git config --global dark true               # or light = true, or omit for auto
git config --global delta.navigate true     # use n and N to move between diffs
git config --global delta.side-by-side true
git config --global line-numbers true
EOF
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
