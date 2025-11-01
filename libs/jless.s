# Command-line pager for JSON data

# shellcheck disable=SC2034
libs_lic=MIT
libs_ver=0.9.0
libs_url=https://github.com/PaulJuliusMartinez/jless/archive/refs/tags/v0.9.0.tar.gz
libs_sha=43527a78ba2e5e43a7ebd8d0da8b5af17a72455c5f88b4d1134f34908a594239

is_linux && libs_dep+=( libxcb )

# configure args
libs_args=(
)

libs_build() {
    # fix dependencies of static libxcb
    #export RUSTFLAGS="-L $PREFIX/lib -l static=Xau -l static=Xdmcp"
    is_linux && export RUSTFLAGS="$($PKG_CONFIG --libs xcb | sed 's/ -l/ -l static=/g')"

    cargo.setup

    cargo.build

    cmdlet.install "$(find target -name $libs_name)"

    cmdlet.check "$libs_name"
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
