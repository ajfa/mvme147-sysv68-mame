#!/usr/bin/env python3
"""console.py SECONDS [SCRIPT] -- MAME-ARGS...

Start MAME headless with the MVME147 console on a null_modem bitbanger that
connects to a TCP port this script listens on, log everything the board
prints to $LOGDIR/console.log and play SCRIPT, one command per line:

  wait TEXT    wait until TEXT has been printed (after the previous match)
  send TEXT    type TEXT and a carriage return, one character at a time
  sleep N      wait N seconds (real time)
  answer TEXT|REPLY
               from now on, type REPLY whenever TEXT is printed (for
               questions that only come up sometimes)

MAME runs unthrottled and stops after SECONDS of emulated time. Set
REALTIME=1 to run it at real speed instead: a login prompt times out after
60 emulated seconds, and unthrottled typing takes several of them per key.

Environment: MAME (the vme binary), ROMPATH (directory with mvme147.zip),
LOGDIR (default: the current directory).
"""
import os, socket, subprocess, sys, time

mame_bin = os.environ.get("MAME", "./vme")
rompath = os.environ.get("ROMPATH", "roms")
logdir = os.environ.get("LOGDIR", ".")

secs = float(sys.argv[1])
rest = sys.argv[2:]
script = []
if rest and rest[0] != "--":
    script = [l.rstrip("\n") for l in open(rest[0])]
    rest = rest[1:]
if rest and rest[0] == "--":
    rest = rest[1:]

srv = socket.socket()
srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
srv.bind(("127.0.0.1", 0))
srv.listen(1)
port = srv.getsockname()[1]

# no display at all: SDL would still open a window with -video none
env = dict(os.environ, SDL_VIDEODRIVER="dummy", SDL_AUDIODRIVER="dummy")
for k in ("DISPLAY", "WAYLAND_DISPLAY", "XDG_SESSION_TYPE"):
    env.pop(k, None)
cmd = [mame_bin, "miniforce", "-vme:slot1", "mvme147",
       "-vme:slot1:mvme147:rs232trm", "null_modem",
       "-bitb", "socket.127.0.0.1:%d" % port,
       "-rompath", rompath, "-video", "none", "-sound", "none",
       "-skip_gameinfo", "-seconds_to_run", str(int(secs) + 5)] + rest
if not os.environ.get("REALTIME"):
    cmd.insert(cmd.index("-skip_gameinfo"), "-nothrottle")
out = open(os.path.join(logdir, "mame.log"), "w")
mame = subprocess.Popen(cmd, env=env, stdout=out, stderr=subprocess.STDOUT)
srv.settimeout(60)
conn, _ = srv.accept()
conn.setblocking(False)
log = open(os.path.join(logdir, "console.log"), "wb")
seen = b""
t0 = time.time()

answers = []  # [text, reply, position after the last time it was answered]

def pump(dt):
    global seen
    end = time.time() + dt
    while time.time() < end:
        try:
            d = conn.recv(4096)
            if d:
                log.write(d); log.flush()
                seen += d
                for a in answers:
                    i = seen.find(a[0], a[2])
                    if i >= 0:
                        a[2] = i + len(a[0])
                        time.sleep(0.5)
                        for ch in a[1] + b"\r":
                            conn.send(bytes([ch]))
                            time.sleep(0.08)
        except BlockingIOError:
            time.sleep(0.02)
        if mame.poll() is not None:
            return

mark = 0  # a wait looks at everything printed since the previous wait matched
for line in script:
    if line.startswith("wait "):
        want = line[5:].encode()
        while want not in seen[mark:] and time.time() - t0 < secs \
                and mame.poll() is None:
            pump(0.2)
        i = seen.find(want, mark)
        mark = i + len(want) if i >= 0 else len(seen)
    elif line.startswith("send "):
        for ch in line[5:].encode() + b"\r":
            conn.send(bytes([ch]))
            pump(0.08)
    elif line.startswith("sleep "):
        pump(float(line[6:]))
    elif line.startswith("answer "):
        text, reply = line[7:].split("|", 1)
        answers.append([text.encode(), reply.encode(), len(seen)])
if not script:  # no script: just watch the console until the time runs out
    while time.time() - t0 < secs and mame.poll() is None:
        pump(0.5)
mame.terminate()
try:
    mame.wait(10)
except subprocess.TimeoutExpired:
    mame.kill(); mame.wait()
print("mame exit", mame.returncode, "bytes", len(seen))
