# all cmdlets

# shellcheck disable=SC2034
libs_type=.PHONY

libs_ver="$(cat VERSION)"

# only cmdlets here, no libraries
libs_dep=(
    # zip
    gtar unrar unzip
    # utils
    coreutils gsed gawk findutils grep gmake
    # shell
    bash ctags shfmt ripgrep
    # net
    wget curl iperf3
    # multimedia
    ffmpeg
    # misc
    lazygit act htop
)

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
