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

#MINGW_TOOLS=(coreutils)
MINGW_ARCH="$(uname -m)-w64-mingw32"

CYGWIN_TOOLS=(coreutils bash grep gawk gsed curl gtar)
CYGWIN_ARCH="$(uname -m)-pc-cygwin"

info() {
    echo -e "-- ✨ \\033[32m$*\\033[39m" 1>&2
}

die() {
    echo -e "** ❌ \\033[31m$*\\033[39m" 1>&2
    exit 1
}

# Linux FHS
info "Create Linux FHS"
mkdir -pv bootstrap/{bin,etc,tmp,usr/bin,home/cmdlets,root}

info "Download bootstrap files"
export CMDLETS_PREBUILTS=bootstrap

for x in "${MINGW_TOOLS[@]}"; do
    CMDLETS_ARCH="$MINGW_ARCH" bash cmdlets.sh fetch "$x"
done

for x in "${CYGWIN_TOOLS[@]}"; do
    CMDLETS_ARCH="$CYGWIN_ARCH" bash cmdlets.sh fetch "$x"
done

info "Download curl ca-bundle.crt"
test -f bootstrap/bin/curl-ca-bundle.crt ||
    curl --insecure https://curl.se/ca/cacert.pem -o bootstrap/bin/curl-ca-bundle.crt

info "Prepare shell environment"
bash libs.sh make_entry bootstrap/bin/bash.exe bootstrap/bin/sh.exe

cp -f cmdlets.sh        bootstrap
cp -f win32/cygwin1.dll bootstrap/bin

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
# etc/profile
export USER="cmdlets"
export LOGIN="cmdlets"
export HOME="/home/cmdlets"

export PATH=/bin:/usr/bin:$PATH
export TERM=xterm-256color
export PS1="[\e[31mcmdlets\e[m] \e[34m\w \e[32m\$\e[m "

echo "🌹 Welcome to cmdlets Shell Env! 🌹"
$SHELL --version | head -n1

cd "$HOME" || cd /
EOF

cat << 'EOF' > bootstrap/etc/bash.bashrc
# bash.bashrc
alias ll='ls -lha --color=auto'
alias grep='grep --color=auto'
EOF

cat << 'EOF' > bootstrap/shell.bat
@echo off

set "PATH=%~dp0;%~dp0bin;%PATH%"

sh.exe -login -i
EOF
sed -i 's/$/\r/' bootstrap/shell.bat

cat << 'EOF' > bootstrap/cmdlets.bat
@echo off

set "PATH=%~dp0;%~dp0bin;%PATH%"

sh.exe -c cmdlets.sh" _ %*
exit /b %errorlevel%
EOF
sed -i 's/$/\r/' bootstrap/cmdlets.bat
