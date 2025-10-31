# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
#
# Docker clients

# shellcheck disable=SC2034,SC2248
libs_ver=28.5.1
libs_url=https://github.com/docker/cli/archive/refs/tags/v$libs_ver.tar.gz
libs_sha=3872f03dd3d1e2769ecad57c8744743e72ad619f72f1897f4886fd44746337cd

compose_ver=v2.40.1
buildx_ver=v0.29.1

libs_resources=(
    "https://github.com/docker/compose/archive/refs/tags/$compose_ver.tar.gz;1f6a066533f25ae61fac7b196c030d10693b8669f21f3798e738d70cea158853"
    "https://github.com/docker/buildx/archive/refs/tags/$buildx_ver.tar.gz;20f62461257d3f20ac98c6e6d3f22ca676710644d9e4688c2e4c082bfba9b619"
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
    go.build -ldflags="'-X github.com/docker/cli/cli/version.Version=$libs_ver -X github.com/docker/cli/cli/version.GitCommit=$(git_version)'" -o docker github.com/docker/cli/cmd/docker &&

    # docker plugins
    (
        # docker compose
        pushd compose-*

        go.build -ldflags="'-X github.com/docker/compose/v2/internal.Version=$compose_ver'" -o ../docker-compose ./cmd
    ) &&

    (
        # docker buildx
        pushd buildx-*

        go.build -ldflags="'-X github.com/docker/buildx/version.Version=$buildx_ver'" -o ../docker-buildx ./cmd/buildx
    ) &&

    # install tools
    cmdlet docker                          &&
    cmdlet docker-compose                  &&
    cmdlet docker-buildx                   &&
    # install all tools as one pkgfile
    pkgfile docker bin/docker bin/docker-* &&

    check docker-compose version           &&
    check docker-buildx version            &&
    check docker --version

    caveats << EOF
static prebuilt docker client @ $libs_ver

Plugins:
    docker-compose @ $compose_ver
    docker-buildx  @ $buildx_ver

    plugins in executable path will be loaded first.

Install docker client with plusins:

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
