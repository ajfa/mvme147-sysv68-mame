#!/usr/bin/env python3
"""coff.py FILE [sections | sym NAME-REGEX | addr OFFSET|VADDR...]: m68k COFF (SysV/68) helper.

sections      list section headers
sym REGEX     symbols whose name matches
addr X...     for each file offset (0x...) or virtual address (v0x...): section, vaddr and nearest symbol
"""
import re, struct, sys

d = open(sys.argv[1], "rb").read()
magic, nscns, timdat, symptr, nsyms, opthdr, flags = struct.unpack(">HHIIIHH", d[:20])
secs = []
for i in range(nscns):
    o = 20 + opthdr + 40 * i
    name, paddr, vaddr, size, scnptr, relptr, lnnoptr, nreloc, nlnno, sflags = struct.unpack(">8sIIIIIIHHI", d[o:o + 40])
    secs.append((name.rstrip(b"\0").decode(), vaddr, size, scnptr))

strtab = symptr + 18 * nsyms
syms = []
i = 0
while i < nsyms:
    o = symptr + 18 * i
    e = d[o:o + 18]
    if e[:4] == b"\0\0\0\0":
        off = struct.unpack(">I", e[4:8])[0]
        name = d[strtab + off:d.index(b"\0", strtab + off)].decode("latin-1")
    else:
        name = e[:8].rstrip(b"\0").decode("latin-1")
    value, scnum, typ, sclass, naux = struct.unpack(">IhHBB", e[8:18])
    if scnum > 0 and sclass in (2, 3, 6):
        syms.append((value, name))
    i += 1 + naux
syms.sort()

def nearest(v):
    best = None
    for a, n in syms:
        if a <= v:
            best = (a, n)
        else:
            break
    return "%s+0x%x" % (best[1], v - best[0]) if best else "?"

cmd = sys.argv[2] if len(sys.argv) > 2 else "sections"
if cmd == "sections":
    for s in secs:
        print("%-8s vaddr=%08x size=%08x file=%08x" % s)
elif cmd == "sym":
    for a, n in syms:
        if re.search(sys.argv[3], n):
            print("%08x %s" % (a, n))
elif cmd == "addr":
    for x in sys.argv[3:]:
        if x.startswith("v"):
            v = int(x[1:], 0)
            print("%08x %s" % (v, nearest(v)))
            continue
        off = int(x, 0)
        for name, vaddr, size, scnptr in secs:
            if scnptr <= off < scnptr + size:
                v = vaddr + off - scnptr
                print("%s file %x -> %s %08x %s" % (x, off, name, v, nearest(v)))
