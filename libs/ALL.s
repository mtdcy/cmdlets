# all cmdlets

# shellcheck disable=SC2034
libs_type=.PHONY

libs_ver="$(cat VERSION)"

# only cmdlets here, no libraries
libs_dep=(
    # basic
    coreutils gsed gawk findutils grep less file
    gmake checkmake
    # zip
    gtar unrar unzip pigz pbzip2 pixz plzip
    # shell
    bash bash32 bash44 zsh
    shellcheck shfmt ctags ripgrep
    tmux htop
    # net
    wget curl iperf3
    # multimedia
    ffmpeg imagemagick exiv2
    # database
    sqlite
    # vcs
    git patch delta lazygit
    # go
    go go-tools
    # misc
    docker act
)

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
