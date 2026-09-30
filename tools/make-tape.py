#!/usr/bin/env python3
"""make-tape.py OUT FILE...: build a SIMH .tap image, 512-byte records, one tape mark per file."""
import struct, sys

out = open(sys.argv[1], "wb")
for name in sys.argv[2:]:
    data = open(name, "rb").read()
    if len(data) % 512:
        sys.exit("%s: %d is not a multiple of 512" % (name, len(data)))
    for i in range(0, len(data), 512):
        out.write(struct.pack("<I", 512) + data[i:i + 512] + struct.pack("<I", 512))
    out.write(struct.pack("<I", 0))  # tape mark
    print("%s: %d records" % (name, len(data) // 512))
out.write(struct.pack("<I", 0))  # second tape mark: end of recorded medium
out.close()
