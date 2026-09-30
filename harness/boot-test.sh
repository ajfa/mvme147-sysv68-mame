#!/bin/bash
# boot-test.sh: boot a copy of the installed disk at real speed, log in, shut down cleanly.
#   MAME, ROMPATH, WORK as for install.sh
set -e
here=$(cd "$(dirname "$0")" && pwd)
export MAME=$(realpath "${MAME:-mame/vme}")
export ROMPATH=$(realpath "${ROMPATH:-roms}")
WORK=${WORK:-work}
export LOGDIR=$(realpath "$WORK")
cd "$WORK"
cp sysv68.chd boot-test.chd
mkdir -p nvram/miniforce
nv=nvram/miniforce/vme_slot1_mvme147_m48t18
[ -f "$nv" ] || head -c 2048 /dev/zero > "$nv"
REALTIME=1 python3 "$here/console.py" 400 "$here/boot-test.txt" -- -hard boot-test.chd -nvram_directory nvram
rm -f boot-test.chd
grep -a "M68030\|secured for powering down" console.log
