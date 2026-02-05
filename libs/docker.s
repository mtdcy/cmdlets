# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
#
# Docker clients

# shellcheck disable=SC2034,SC2248
libs_ver=29.2.1
libs_url=https://github.com/docker/cli/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=33a5c92198a2e57a6012c6f7938d69c72adf751584bc0c98d8d91e555b1c8f0a

compose_ver=5.0.2
buildx_ver=0.31.1

libs_resources=(
    "https://github.com/docker/compose/archive/refs/tags/v$compose_ver.tar.gz;9cd91c987bfe5924c1883b7ccd82a5a052e97d0ea149d6a00b2a8c3bf3148009"
    "https://github.com/docker/buildx/archive/refs/tags/v$buildx_ver.tar.gz;2f2069554305c9659dd4a2b4eb10c7aeab97e52e89cfeeda07f0c0c43d19ee80"
)

libs_build() (
    # setup go modules path
    export GOPATH="$PWD"

    # Fix: date: invalid option -- 'j'
    export BUILDTIME="$(TZ=UTC date)"

    # borrow from homebrew
    is_darwin && export CGO_ENABLED=1 || true

    mkdir -pv src/github.com/docker
    ln -srfv . src/github.com/docker/cli

    # -X main.version not working for docker
    go.build -ldflags="'-X github.com/docker/cli/cli/version.Version=$libs_ver -X github.com/docker/cli/cli/version.GitCommit=$(git.version)'" -o docker github.com/docker/cli/cmd/docker

    # docker plugins
    (
        # docker compose
        pushd compose-*

        go.build -ldflags="'-X github.com/docker/compose/v${compose_ver%%.*}/internal.Version=v$compose_ver'" -o ../docker-compose ./cmd
    ) || die

    (
        # docker buildx
        pushd buildx-*

        go.build -ldflags="'-X github.com/docker/buildx/version.Version=v$buildx_ver'" -o ../docker-buildx ./cmd/buildx
    ) || die

    # install tools
    cmdlet.install docker
    cmdlet.install docker-compose
    cmdlet.install docker-buildx

    cmdlet.check docker-compose
    cmdlet.check docker-buildx
    cmdlet.check docker --version

    # install all tools as one pkgfile
    cmdlet.pkgfile docker bin/docker bin/docker-*

    caveats << EOF
static prebuilt docker client v$libs_ver

Plugins:
    docker-compose v$compose_ver
    docker-buildx  v$buildx_ver

    plugins in executable path will be loaded first.

Install docker client with plugins:

    cmdlets.sh install docker
EOF
)

# patch: load plugins from executable path
__END__
diff -ruN a/cli-plugins/manager/manager.go b/cli-plugins/manager/manager.go
--- a/cli-plugins/manager/manager.go	2025-10-08 10:50:32
+++ b/cli-plugins/manager/manager.go	2025-10-19 11:05:52
@@ -59,12 +59,18 @@
 func getPluginDirs(cfg *configfile.ConfigFile) []string {
 	var pluginDirs []string

+	ex, err := os.Executable()
+	if err != nil {
+		panic(err)
+	}
+
 	if cfg != nil {
 		pluginDirs = append(pluginDirs, cfg.CLIPluginsExtraDirs...)
 	}
 	pluginDir := filepath.Join(config.Dir(), "cli-plugins")
+	pluginDirs = append(pluginDirs, filepath.Dir(ex))
 	pluginDirs = append(pluginDirs, pluginDir)
 	pluginDirs = append(pluginDirs, defaultSystemPluginDirs...)
 	return pluginDirs
 }
