# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
# Portable library for network traffic capture

# shellcheck disable=SC2034
libs_lic='BSD-3-Clause'
libs_ver=1.10.6
libs_url=https://www.tcpdump.org/release/libpcap-1.10.6.tar.gz
libs_sha=872dd11337fe1ab02ad9d4fee047c9da244d695c6ddf34e2ebb733efd4ed8aa9

libs_deps=( )

is_linux && libs_deps+=( libnetfilter ) # libnl

libs_args=(
    -Wno-dev

    # disabled features
    -DDISABLE_DBUS=ON

    # XXX: cmake will fail if build only static libraries
    -DBUILD_SHARED_LIBS=OFF
)

is_listed libnetfilter libs_deps && libs_args+=( -DBUILD_WITH_LIBNL=ON ) || libs_args+=( -DBUILD_WITH_LIBNL=OFF )

# windows: needs Npcap drivers
if is_mingw; then
    libs_deps+=( openssl )
    libs_args+=( -DPCAP_TYPE=null )
fi

libs_build() {
    if is_mingw; then
        # fix undefined reference to `xxxx' when build rpcapd by
        # link win32 libraries manually
        local libs=()
        for x in $($PKG_CONFIG --libs-only-l --static openssl); do
            case "$x" in
                -l*)    libs+=( "${x#-l}" ) ;;
            esac
        done

        # append win32 libraries
        sed -i rpcapd/CMakeLists.txt \
            -e "/target_link_libraries/s/$/& ${libs[*]}/"
    fi

    cmake.setup

    cmake.build 

    # fix pc files
    is_mingw && pkgconf libpcap.pc $($PKG_CONFIG --libs-only-l --static openssl)

    # fix pcap-config
    sed -i pcap-config \
        -e 's/^static=.*/static=1/' \
        -e 's/^static_pcap_only=.*/static_pcap_only=1/' \

    pkgfile $libs_name -- cmake.install --component Unspecified

    is_mingw && cmdlet.install run/rpcapd.exe || true
}

__END__

# build static libpcap only not working with cmake
--- a/CMakeLists.txt	2026-02-15 13:51:53.047779429 +0800
+++ b/CMakeLists.txt	2026-02-15 13:51:58.423193036 +0800
@@ -3248,10 +3248,12 @@
         # For compatibility, build the shared library without the "lib" prefix on
         # MinGW as well.
         #
+        if(BUILD_SHARED_LIBS)
         set_target_properties(${LIBRARY_NAME} PROPERTIES
             PREFIX ""
             OUTPUT_NAME "${LIBRARY_NAME}"
         )
+        endif(BUILD_SHARED_LIBS)
         set_target_properties(${LIBRARY_NAME}_static PROPERTIES
             OUTPUT_NAME "${LIBRARY_NAME}"
         )
--- a/rpcapd/CMakeLists.txt	2026-02-15 15:30:56.287293530 +0800
+++ b/rpcapd/CMakeLists.txt	2026-02-15 16:14:52.971445456 +0800
@@ -92,7 +92,7 @@
   endif()
 
   if(WIN32)
-    target_link_libraries(rpcapd ${LIBRARY_NAME}
+    target_link_libraries(rpcapd ${LIBRARY_NAME}_static
       ${RPCAPD_LINK_LIBRARIES} ${PCAP_LINK_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})
   else(WIN32)
     target_link_libraries(rpcapd ${LIBRARY_NAME}_static
