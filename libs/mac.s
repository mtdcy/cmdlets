#
# shellcheck disable=SC2034
libs_lic="3-Clause BSD"
libs_ver=11.62
# monkeysaudio server always return 200
#  => no version in url, so auto update won't work
libs_url=https://monkeysaudio.com/files/MAC_1162_SDK.zip
libs_sha=9945408555424f1f81d69d8bba46f191331219c144b7576158f1e4d9cff67024

libs_args=(
    -DBUILD_SHARED=OFF
)

libs_build() {
    cmake . && make || return $?

    cmdlet ./mac && check mac --version
}


# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
