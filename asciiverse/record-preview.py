#!/usr/bin/env python3
"""Records asciiverse/tintin.cast, TinTin++'s catalog preview, at 100x30
(hub/RECORDING.md): the welcome screen, then `#ssl bat batmud.bat.org 2022`
typed in, showing the TLS connection and BatMUD's greeting. Nothing is sent
to the MUD beyond connecting. Usage, from the repo root with src/tt++ built:
    python3 asciiverse/record-preview.py"""
import os, pty, shutil, struct, fcntl, select, tempfile, termios, time

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
home = tempfile.mkdtemp()
env = dict(os.environ, HOME=home, TERM="xterm-256color", COLORTERM="truecolor", LANG="C.UTF-8")
cmd = "#ssl bat batmud.bat.org 2022"
keys = [(4.0, b"")] + [(0.09, c.encode()) for c in cmd] + [(0.6, b"\r"), (10.0, b"#end\r"), (1.5, b"")]

pid, fd = pty.fork()
if pid == 0:
    os.execvpe("asciinema", ["asciinema", "rec", "--overwrite", "-q", "-i", "2",
        "--capture-env", "TERM,COLORTERM,LANG", "-c", f"{root}/src/tt++",
        f"{root}/asciiverse/tintin.cast"], env)
fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 100, 0, 0))
for wait, key in keys:
    end = time.time() + wait
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.05)
        if r:
            try: os.read(fd, 65536)
            except OSError: break
    if key: os.write(fd, key)
try: os.waitpid(pid, 0)
except ChildProcessError: pass
shutil.rmtree(home)
