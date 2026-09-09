# Distributed revision control system

# shellcheck disable=SC2034,SC2154
libs_stable=1 # no auto update
libs_lic=GPLv2
libs_ver=2.52.0
libs_rev=5
libs_url="https://mirrors.edge.kernel.org/pub/software/scm/git/git-$libs_ver.tar.xz"
libs_sha=3cd8fee86f69a949cb610fee8cd9264e6873d07fa58411f6060b3d62729ed7c5
libs_deps=(zlib zstd pcre2 libiconv expat curl mbedtls)
# mbedtls : git 对其没有直接依赖，这里只是用来控制后面的 libs_args

is_listed mbedtls libs_deps || is_darwin || libs_deps+=(openssl)

#is_mingw && libs_deps+=( libgnurx )

libs_args=(
    # no /etc/gitconfig
    -Dgitconfig=/no-etc-gitconfig

    # disabled features
    -Dperl=enabled      # need by netrc
    -Drust=disabled
    -Dgitweb=disabled
    -Dpython=disabled
    -Dgettext=disabled
    -Ddocs=''
    -Dtests=false
    -Dregex=disabled # system regex
    --wrap-mode=nodownload

    # contrib
    -Dcontrib=subtree
)

# helpers
if is_darwin; then
    libs_args+=(-Dcredential_helpers=osxkeychain)
elif is_mingw; then
    libs_args+=(-Dcredential_helpers=wincred)
elif is_cygwin; then
    libs_args+=(-Dcredential_helpers=netrc)

    # https://github.com/msys2/MSYS2-packages/tree/master/git
    libs_patches=(
        https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/git/git-2.3.5-mingw-pwd.patch
        https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/git/git-2.8.2-Cygwin-Allow-DOS-paths.patch
        https://github.com/msys2/MSYS2-packages/raw/refs/heads/master/git/0001-aspell.patch
    )
else
    libs_args+=(-Dcredential_helpers=netrc)
fi

is_listed pcre2    libs_deps && libs_args+=(-Dpcre2=enabled)           || libs_args+=(-Dpcre2=disabled)
is_listed expat    libs_deps && libs_args+=(-Dexpat=enabled)           || libs_args+=(-Dexpat=disabled)
is_listed libiconv libs_deps && libs_args+=(-Diconv=enabled)           || libs_args+=(-Diconv=disabled)
is_listed openssl  libs_deps && libs_args+=(-Dhttps_backend=openssl)   || libs_args+=(-Dhttps_backend=auto)

# libcurl + mbedtls
is_listed mbedtls  libs_deps && libs_args+=(
    -Dlibcurl:tls=mbedtls
    -Dlibcurl:http3=disabled
    -Dlibcurl:ngtcp2=disabled
)

#1. 避免硬编码 PREFIX
#2. 避免使用主机路径
#       /Library/Developer/CommandLineTools/usr/bin/git'
#       /usr/lib/git-core
#3. Cygwin 使用 FHS 路径，其他则使用入口脚本设置环境变量
if is_cygwin || is_mingw; then
    # libexec & bin 使用同目录
    _LIBEXEC=bin
else
    _LIBEXEC=share/git-core/libexec
fi
libs_args+=(-Dlibexecdir="/$_LIBEXEC" -Ddatadir=/share)
# mergetools : <libexecdir>/mergetools
# templates  : <datadir>/git-core/templates

libs_build() {
    #libs.requires libgnurx

    # rename git => git-core
    #sed -i '/^project/s/\<git\>/git-core/' meson.build

    # always find tools in host
    sed -i '/Program Files/d' meson.build

    # posix winpthread instead win32 thread
    if is_posix; then
        sed -i '/win32\/pthread.c/d' meson.build
        rm -f compat/win32/pthread.h
    fi

    #cargo.setup # libgitcore requires cargo/rust

    meson.setup

    meson.compile

    # standalone cmds: binaries and bash scripts
    local cmds=(
        # basic
        git-daemon git-shell git-submodule git-sh-setup
        # core utils
        git-receive-pack git-upload-pack git-upload-archive
        # http
        git-http-backend git-http-fetch git-http-push
        # merge & difftool
        git-mergetool git-difftool--helper
        # https
        git-remote-http git-remote-https
        git-remote-ftp git-remote-ftps
        # misc
        git-request-pull
    )

    if is_darwin; then
        cmds+=(contrib/credential/osxkeychain/git-credential-osxkeychain)
    elif is_mingw; then
        cmds+=(contrib/credential/wincred/git-credential-wincred)
    else
        cmds+=(contrib/credential/netrc/git-credential-netrc)
    fi

    if ! is_mingw; then
        cmds+=(contrib/subtree/git-subtree)

        # git-sh-setup: NO_GETTEXT
        sed -i git-sh-setup \
            -e '/git-sh-i18n/d' \
            -e 's/eval_gettextln/eval echo/g' \
            -e 's/eval_gettext/eval echo/g' \
            -e 's/gettextln/echo/g' || die "modify git-sh-setup failed."

        # git-mergetool:
        sed -i git-mergetool \
            -e 's/git-sh-setup/$(which git-sh-setup)/' \
            -e '/git-mergetool--lib/r git-mergetool--lib' \
            -e '/git-mergetool--lib/d' || die "modify git-mergetool failed."

        # git-difftool--helper:
        #  #1. GIT_EXTERNAL_DIFF=echo git diff
        #  #2. git difftool --extcmd echo
        #  #3. git difftool --tool vscode
        sed -i git-difftool--helper \
            -e '/git-mergetool--lib/r git-mergetool--lib' \
            -e '/git-mergetool--lib/d' ||
               die "modify git-difftool--helper failed."
    fi

    # windows : 使用 exe 作为主入口
    #  cygwin => 需要加载当前目录的 cygwin1.dll
    #  mingw  => 不支持 shell 脚本
    mkdir -p bin
    if is_cygwin || is_mingw; then
        mv git.exe bin/
    else
        # 将主程序放入libexec
        cmds+=(git)

        # override default wrapper
        cat << EOF > bin/git
#!/usr/bin/env bash

export GIT_EXEC_PATH="\$(readlink -f "\$(dirname "\$0")/../$_LIBEXEC")"
export MERGE_TOOLS_DIR="\$GIT_EXEC_PATH/mergetools"
export GIT_TEMPLATE_DIR="\$GIT_EXEC_PATH/../templates"
export PATH="\$GIT_EXEC_PATH:\$PATH"

exec "\$GIT_EXEC_PATH/git" "\$@"
EOF
        chmod a+x bin/git
    fi

    mkdir -p libexec
    for x in "${cmds[@]}"; do
        if test -f "$x"; then
            cp -f "$x" libexec/
        else
            cp -f "$x$_BINEXT" libexec/
        fi
    done

    # install git + mergetools + templates
    cmdlet.pkginst git \
            bin                     ./bin/git \
            $_LIBEXEC               ./libexec/* \
            $_LIBEXEC/mergetools    ../mergetools/* \
            share/git-core/templates ./templates/*

    cmdlet.verify -- git --version

    cmdlet.caveats << EOF
static built git $libs_ver without i18n
EOF

    if is_darwin; then
        cmdlet.caveats << EOF

osxkeychain:
    git config --global credential.helper osxkeychain
EOF
    else
        cmdlet.caveats << EOF

netrc:
    git config --global credential.helper netrc
    touch ~/.netrc
EOF
    fi
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
