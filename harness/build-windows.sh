#!/bin/bash
# build-windows.sh: native Windows build with MSYS2 (MINGW64), run from an MSYS2 shell:
#   MSYSTEM=MINGW64 bash -l harness/build-windows.sh
#   MAME_SRC    MAME tree at 60e07cb1 with the patches applied (default: ./mame)
#   MSYS2_ROOT  where MSYS2 is installed (default: C:/msys64)
#   JOBS        parallel jobs (default: 4)
# Needs mingw-w64-x86_64-gcc and make from MSYS2, and a regular Windows Python
# (not the Microsoft Store alias). If genie hangs while it builds itself, run
# this from a visible shell rather than a hidden process.
set -u
MSYS2_ROOT=${MSYS2_ROOT:-C:/msys64}
export OS=Windows_NT
export MSYSTEM=MINGW64
export MINGW_PREFIX=/mingw64
export MINGW64=$MSYS2_ROOT/mingw64
export PATH=/mingw64/bin:/usr/bin:$PATH
cd "${MAME_SRC:-mame}" || exit 1
PY=${PYTHON:-$(ls -d /c/Users/*/AppData/Local/Programs/Python/Python3*/python.exe 2>/dev/null | head -1)}
echo "python: $PY"
mingw32-make SUBTARGET=vme SOURCES=src/mame/force/miniforce.cpp \
	PYTHON_EXECUTABLE="$PY" MINGW64=$MSYS2_ROOT/mingw64 PTR64=1 REGENIE=1 \
	TOOLCHAIN=$MSYS2_ROOT/mingw64/bin/ NOWERROR=1 OPTIMIZE=2 SYMBOLS=0 TOOLS=0 -j"${JOBS:-4}"
rc=$?
ls -l vme.exe 2>/dev/null
exit $rc
