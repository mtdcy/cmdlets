#!/bin/bash
# =============================================================================
#  bootstrap.windows.sh - Prepare Windows tools using cmdlets.sh
#
#  Copyright (c) 2026, mtdcy.chen@gmail.com
#  Licensed under BSD 2-Clause License
#
#  Usage: ./bootstrap.windows.sh
# =============================================================================

set -eo pipefail

export CMDLETS_PREBUILTS=bootstrap
export CMDLETS_ARCH="$(uname -m)-pc-cygwin"

CYGWIN_TOOLS=(
    # core
    bash coreutils grep gawk gsed which
    findutils diffutils file
    # +ssl +git
    openssl curl git less
    # compress and decompress
    gtar gzip xz
)

info() {
    echo -e "-- ✨ \\033[32m$*\\033[39m" 1>&2
}

die() {
    echo -e "** ❌ \\033[31m$*\\033[39m" 1>&2
    exit 1
}

TEMPDIR="$(mktemp -d)"
_on_exit() {
    wait
    rm -rf "$TEMPDIR"
}
trap _on_exit EXIT
trap 'exit 1' INT   # ctrl-c

# Linux FHS
info "Create Linux FHS"
mkdir -pv bootstrap/{bin,lib,etc,tmp,home/cmdlets,root}
mkdir -pv bootstrap/usr/{bin,lib}
# cygwin 会自动处理 /usr/bin 与 /bin 之间的关系
# !! 永远不要同时写入 /bin & /usr/bin，否则 mini_rootfs 会出错 !! #

info "Prepare bootstrap files"

curl -fsSL https://mirrors.aliyun.com/cygwin/x86_64/release/cygwin/cygwin-3.6.10-1-x86_64.tar.xz |
    tar -C "$TEMPDIR" -xvJ

# 只取最小工具集
cp -fv "$TEMPDIR/usr/bin/cygwin1.dll"   bootstrap/bin
cp -fv "$TEMPDIR/usr/bin/cygcheck.exe"  bootstrap/bin
cp -fv "$TEMPDIR/usr/bin/cygpath.exe"   bootstrap/bin

cp -fv cmdlets.sh                       bootstrap
cp -fv win32/make_entry.exe             bootstrap/bin

bash cmdlets.sh fetch "${CYGWIN_TOOLS[@]}"

info "Prepare shell environment"

bash libs.sh make_entry bash.exe bootstrap/bin/sh.exe

cat << 'EOF' > bootstrap/etc/fstab
# -------------------------------------------------------------------
# bash.exe/cygwin 虚拟文件系统动态挂载表 (fstab)
# -------------------------------------------------------------------
# 1. 利用 none / cygdrive 机制，自动把 Windows 的盘符重定向到 /media/c 下
none /media cygdrive binary,user,noacl 0 0

# 2. 将当前 bash.exe 所在的物理根目录，无感锁死硬映射为 POSIX 的虚拟根目录 '/'
. / mini_rootfs binary,user,noacl 0 0
EOF

cat << 'EOF' > bootstrap/etc/nsswitch.conf
# -------------------------------------------------------------------
# 专属于 cmdlets 的动态用户自愈转换表 (nsswitch.conf)
# -------------------------------------------------------------------
# 让 passwd 引擎完全放弃 files(静态文件)，直接锁定全新的 db(动态算力)
passwd: db
group: db

db_home: /home/%U
db_shell: /bin/bash
EOF

cat << 'EOF' > bootstrap/etc/profile
# /etc/profile

test -d /etc/ssl || /update-ca-certificates

export USER="cmdlets"
export LOGIN="cmdlets"
export HOME="/home/cmdlets"

export PATH=/bin:$PATH
export TERM=xterm-256color
export PS1="[\e[31mcmdlets\e[m] \e[34m\w \e[32m\$\e[m "

export LS_COLORS='no=00;37:fi=00:di=34;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=31;40:cd=31;40:su=31;40:sg=31;40:tw=31;40:ow=31;40:'

alias ll='ls -lha --color=auto'
alias grep='grep --color=auto'
alias which='command -v'

echo "🌹 Welcome to cmdlets Shell Env! 🌹"
$SHELL --version | head -n1

cd "$HOME" || cd /
EOF

cat << 'EOF' > bootstrap/update-ca-certificates
#!/bin/sh

set -eo pipefail

: "${CA_CERT:=/etc/ssl/certs/ca-bundle.crt}"

mkdir -pv "${CA_CERT%/*}"

echo "-- ✨ curl ca certs file"
curl --insecure -fSL https://curl.se/ca/cacert.pem -o "$CA_CERT"

echo "-- ✨ set alternative ca certs file path"
#1. OpenSSL default cert.pem
ln -srfv "$CA_CERT" /etc/ssl/cert.pem
#2. curl in-place ca-bundle.crt
ln -srfv "$CA_CERT" /bin/curl-ca-bundle.crt

echo "-- ✨ check ca certs file"
echo | openssl s_client -connect google.com:443 | grep --color=auto "Verification: OK"
curl -fIL https://www.google.com
EOF

info "Prepare Program Entrance"

PROG=shell.bat && info "prepare $PROG"
cat << 'EOF' > bootstrap/$PROG
@echo off
setlocal
set "PATH=%~dp0bin;%~dp0usr\bin;%PATH%"

if "%~1"=="" (
    "%~dp0bin\bash.exe" -login -i
) else (
    "%~dp0bin\bash.exe" -c "%*"
)
EOF
sed -i 's/$/\r/' bootstrap/$PROG

PROG=cmdlets.bat && info "prepare $PROG"
cat << 'EOF' > bootstrap/$PROG
@echo off
setlocal
set "PATH=%~dp0bin;%~dp0usr\bin;%PATH%"

"%~dp0bin\bash.exe" -c "/cmdlets.sh %*"
exit /b %errorlevel%
EOF
sed -i 's/$/\r/' bootstrap/$PROG

PROG=git.bat && info "prepare $PROG"
cat << 'EOF' > bootstrap/$PROG
@echo off
setlocal
set "PATH=%~dp0bin;%~dp0usr\bin;%PATH%"

set "SSL_CERT_FILE=%~dp0etc\ssl\cert.pem"
set "GIT_EXEC_PATH=%~dp0bin"
set "MERGE_TOOLS_DIR=%GIT_EXEC_PATH%\mergetools"
set "GIT_TEMPLATE_DIR=%~dp0share\git-core\templates"

"%~dp0bin\git.exe" %*
exit /b %errorlevel%
EOF
sed -i 's/$/\r/' bootstrap/$PROG
