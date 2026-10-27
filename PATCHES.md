# Changes from upstream

This is the Asciiverse packaging of [TinTin++](https://github.com/scandum/tintin)
by Igor van den Hoven and contributors, built from upstream's 2.02.61 tag.
Upstream is the `upstream` remote; the `asciiverse` branch carries the
changes below.

## Code

None. TinTin++ is built exactly as released.

## License

2.02.61 is GPL-3.0-or-later (its COPYING file and every source header).
Upstream added an LGPL-2.1 LICENSE file in 2.02.62 (August 2026, not
released when this was packaged), so later versions may change license.

## Packaging (new files, no upstream code touched)

- `asciiverse/build-static.sh`: a fully static Linux build in Alpine. GnuTLS
  has no static package there, so 3.8.13 is built from its release tarball
  (sha256 pinned, checked against Alpine's own APKBUILD) with only what #ssl
  needs.
- `asciiverse/build-macos.sh`: the same for macOS, linking nothing outside
  the system; the script fails if tt++ links any other library.
- `asciiverse/nfpm.yaml`: .deb, .rpm, .apk and Arch packages, named
  `tintin-asciiverse` so they never collide with a distribution's own
  tintin++ (they conflict with it and install the same tt++ command).
- `.github/workflows/release.yml`: builds all of it on a tag.

## Encryption

`#ssl <name> <host> <port>` connects over TLS. TinTin++ pins certificates
instead of checking them against certificate authorities: the first
connection saves the server's certificate in ~/.tintin/ssl/, and later
connections warn if it changes or expires (like SSH).

## Not built

- Windows: upstream ships WinTin++, which bundles Cygwin and Mintty.
- Intel Macs: needs Homebrew's Intel libraries on the build runner.

## Ours

- **How to play it, at the top of README.** A short note on installing and
  starting it with av, or from a release archive; the original text follows
  unchanged.
