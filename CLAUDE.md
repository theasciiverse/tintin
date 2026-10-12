# TinTin++ (Asciiverse packaging)

The console MUD client by Igor van den Hoven, packaged for the Asciiverse
catalog (kind `program`, topic `mud-client`) and as system packages. Not our
code: keep changes small, list every one in PATCHES.md, and offer fixes
upstream.

- Remotes: `upstream` is github.com/scandum/tintin, `origin` is
  github.com/theasciiverse/tintin (public, because the GPL asks that the
  source of what we ship is available).
- Branch `asciiverse` = an upstream release tag plus our commits.
- Release: tag `v<upstream version>-av.<n>` and push it.
- Local static build: `docker run --rm -v "$PWD":/src -w /src alpine:3.22
  sh asciiverse/build-static.sh` leaves `src/tt++`.
- The command is `tt++`. Connect from inside it: `#session <name> <host>
  <port>`, or `#ssl <name> <host> <port>` for TLS.
