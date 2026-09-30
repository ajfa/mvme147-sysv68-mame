#!/usr/bin/env python3
"""s5ls.py IMAGE [PATH] [-x OUTDIR]: list (or extract) a big-endian System V (s5) file system image.

SVR3 s5: superblock at byte 512, 64-byte inodes from block 2, 13 3-byte block
addresses (10 direct, single, double, triple indirect), 16-byte directory entries.
The logical block size comes from s_type (1 = 512, 2 = 1 KB, 3 = 2 KB).
"""
import os, struct, sys

img = open(sys.argv[1], "rb").read()
sb = img[512:1024]
magic, stype = struct.unpack(">II", sb[504:512])
if magic != 0xfd187e20:
    sys.exit("no s5 magic (%08x)" % magic)
bsize = {1: 512, 2: 1024, 3: 2048}[stype]

def block(n):
    return img[n * bsize:(n + 1) * bsize]

def inode(ino):
    off = 2 * bsize + (ino - 1) * 64
    d = img[off:off + 64]
    mode, nlink, uid, gid, size = struct.unpack(">HHHHI", d[:12])
    addr = [int.from_bytes(d[12 + 3 * i:15 + 3 * i], "big") for i in range(13)]
    return mode, size, addr

def blocks(addr):
    per = bsize // 4
    out = [a for a in addr[:10]]
    def indirect(b, level):
        if not b:
            return [0] * (per ** level)
        ptrs = struct.unpack(">%dI" % per, block(b))
        if level == 1:
            return list(ptrs)
        r = []
        for p in ptrs:
            r += indirect(p, level - 1)
        return r
    for lvl, a in ((1, addr[10]), (2, addr[11]), (3, addr[12])):
        if a:
            out += indirect(a, lvl)
    return out

def read(ino):
    mode, size, addr = inode(ino)
    data = b"".join(block(b) if b else bytes(bsize) for b in blocks(addr)[:(size + bsize - 1) // bsize])
    return mode, data[:size]

def listdir(ino):
    _, data = read(ino)
    for i in range(0, len(data), 16):
        n, name = struct.unpack(">H14s", data[i:i + 16])
        if n:
            yield name.rstrip(b"\0").decode("latin-1"), n

def lookup(path):
    ino = 2
    for part in [p for p in path.split("/") if p]:
        ino = dict(listdir(ino))[part]
    return ino

path = sys.argv[2] if len(sys.argv) > 2 and not sys.argv[2].startswith("-") else "/"
ino = lookup(path)
mode, size, addr = inode(ino)
if "-x" in sys.argv:
    out = sys.argv[sys.argv.index("-x") + 1]
    def extract(ino, dest):
        mode, data = read(ino)
        if mode & 0xf000 == 0x4000:
            os.makedirs(dest, exist_ok=True)
            for name, n in listdir(ino):
                if name not in (".", ".."):
                    extract(n, os.path.join(dest, name))
        elif mode & 0xf000 == 0x8000:
            open(dest, "wb").write(data)
    extract(ino, out)
elif mode & 0xf000 == 0x4000:
    for name, n in listdir(ino):
        m, s, a = inode(n)
        kind = {0x4000: "d", 0x8000: "-", 0x2000: "c", 0x6000: "b", 0x1000: "p"}.get(m & 0xf000, "?")
        extra = ("%d,%d" % (a[0] >> 16 & 0xff if False else (a[0] >> 8) & 0xff, a[0] & 0xff)) if kind in "cb" else str(s)
        print("%s%o %6s %s" % (kind, m & 0o7777, extra, name))
else:
    sys.stdout.buffer.write(read(ino)[1])
