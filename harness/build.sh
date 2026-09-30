#!/bin/bash
# build.sh: apply the patches to a MAME checkout at 60e07cb1 and build the vme subtarget.
#   MAME_SRC  MAME source tree (default: ./mame)
#   JOBS      parallel jobs (default: 4)
set -e
repo=$(cd "$(dirname "$0")/.." && pwd)
MAME_SRC=${MAME_SRC:-mame}
cd "$MAME_SRC"
if git apply --check "$repo"/patches/*.patch 2>/dev/null; then
	git apply "$repo"/patches/*.patch
	echo "patches applied"
elif git apply --check -R "$repo"/patches/*.patch 2>/dev/null; then
	echo "patches already applied"
else
	echo "the patches do not apply: is the tree at MAME commit 60e07cb1?" >&2
	exit 1
fi
make SUBTARGET=vme SOURCES=src/mame/force/miniforce.cpp NOWERROR=1 -j"${JOBS:-4}"
ls -l "$PWD/vme"
