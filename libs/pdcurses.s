# a curses library for environments that don't fit the termcap/terminfo model

libs_targets=( windows )

# shellcheck disable=SC2034
libs_ver=4.5.4
libs_url=https://github.com/Bill-Gray/PDCursesMod/archive/refs/tags/v4.5.4.tar.gz
libs_sha=d5efc7f2b7107abe382bdf8bac0a9bfd8e716facbca2bb9cf12dfeb8e1122c4b

libs_deps=( ncurses sdl2 )

libs_args=(
    CC="'$CC'"
    STRIP="'$STRIP'"
    AR="'$AR'"
    WIDE=Y 
    UTF8=Y
    DLL=N
)

libs_build() {
    # DOS for use on DOS
    # OS/2 for use on OS/2
    # SDL 1.x for use as separate SDL version 1 window
    # SDL 2.x for use as separate SDL version 2 window
    # wincon (formerly win32) for use on Windows Console
    # WinGUI for use on Windows Graphics Mode
    # X11 (also called XCurses) for use as separate X11 window
    # VT for use on terminal

    # needs defines matching the make step, see https://github.com/Bill-Gray/PDCursesMod/issues/133
    cat << EOF > pdcurses.h
/* if you want to use the DLL one: #define PDC_DLL_BUILD 1 */
/* if you want to use ncurses compatible mouse: #define PDC_NCMOUSE 1 */
#define PDC_WIDE 1
#define PDC_FORCE_UTF8 1
#include "pdcurses/curses.h"
EOF

    local headers=( curses.h panel.h term.h pdcurses.h )
    local ports=( wincon wingui )

    for port in "${ports[@]}"; do
        make -C "$port" "${libs_args[@]}" LIBNAME=libpdcurses-$port

        make -C "$port" "${libs_args[@]}" LIBNAME=libpdcurses-$port demos

        cmdlet.pkgconf libpdcurses-$port.pc -lpdcurses-$port -luser32 -lshell32 -lgdi32
    done

    cmdlet.pkginst libpdcurses \
        include/pdcurses "${headers[@]}" \
        lib              $(ls ${ports[@]/%/\/libpdcurses-*.a} | xargs) \
        lib/pkgconfig    libpdcurses-*.pc
}

# vim:ft=sh:syntax=bash:ff=unix:fenc=utf-8:et:ts=4:sw=4:sts=4
