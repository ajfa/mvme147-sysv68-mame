#!/bin/bash
# install.sh: install System V/68 R3V7 from its tape onto a new SCSI disk, unattended.
#   MAME     the vme binary built by build.sh (default: ./mame/vme)
#   ROMPATH  directory holding mvme147.zip (default: ./roms)
#   MEDIA    directory with the tape files 42-00111.00 ... 42-00111.15 (default: ./42-00111)
#   WORK     where the tape image, the disk and the logs go (default: ./work)
set -e
here=$(cd "$(dirname "$0")" && pwd)
export MAME=$(realpath "${MAME:-mame/vme}")
export ROMPATH=$(realpath "${ROMPATH:-roms}")
MEDIA=${MEDIA:-42-00111}
WORK=${WORK:-work}
CHDMAN=${CHDMAN:-$(dirname "$MAME")/chdman}
mkdir -p "$WORK/nvram/miniforce"
export LOGDIR=$(realpath "$WORK")

# the tape: 512-byte records, one tape mark per file
[ -f "$WORK/sysv68r3v7.tap" ] || python3 "$here/../tools/make-tape.py" "$WORK/sysv68r3v7.tap" "$MEDIA"/42-00111.[01][0-9]

# a 316 MB disk, the geometry of the Seagate WREN IV the installer offers first
rm -f "$WORK/sysv68.chd"
"$CHDMAN" createhd -o "$WORK/sysv68.chd" -chs 1224,9,56 -ss 512 -c none

# a blank MAME NVRAM is all 0xff, and 147Bug boots a file named by that garbage
nv="$WORK/nvram/miniforce/vme_slot1_mvme147_m48t18"
[ -f "$nv" ] || head -c 2048 /dev/zero > "$nv"

cd "$WORK"
python3 "$here/console.py" 6000 "$here/install.txt" -- \
	-tape sysv68r3v7.tap -hard sysv68.chd -nvram_directory nvram
grep -a "installation is completed" console.log && echo "installed: $WORK/sysv68.chd"
