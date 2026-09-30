#!/bin/bash
# run.sh: boot the installed disk in a MAME window, with MAME's terminal as the console.
#   MAME, ROMPATH, WORK as for install.sh
here=$(cd "$(dirname "$0")" && pwd)
MAME=$(realpath "${MAME:-mame/vme}")
ROMPATH=$(realpath "${ROMPATH:-roms}")
WORK=${WORK:-work}
mkdir -p "$WORK/nvram/miniforce"
nv="$WORK/nvram/miniforce/vme_slot1_mvme147_m48t18"
[ -f "$nv" ] || head -c 2048 /dev/zero > "$nv"
cd "$WORK"
exec "$MAME" miniforce -vme:slot1 mvme147 -rompath "$ROMPATH" -hard sysv68.chd \
	-nvram_directory nvram -autoboot_script "$here/lua/autoboot.lua" \
	-window -nomaximize -skip_gameinfo -natural "$@"
