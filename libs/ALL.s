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
    # net/tools
    wget curl iperf3 aria2
    openssh stuntman coturn
    # net/ping
    inetutils tcping httping arping gping nping hping3
    # net/dns
    bind dnsmasq
    # net/tcp
    tcptraceroute tcpdump
    # net/tunnel
    gost
    # net/debug
    netcat nmap netperf ngrep nload ntopng
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

is_linux && libs_dep+=(
    nftables
)

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
