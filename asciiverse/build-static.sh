#!/bin/sh
# Builds a fully static TinTin++ (tt++) in Alpine: zlib, zstd, pcre2, nettle
# and gmp come as Alpine's static libraries; GnuTLS has no static package
# there, so it is built from its release tarball with only what #ssl needs.
# Run from the repository root inside alpine:3.22:
#   docker run --rm -v "$PWD":/src -w /src alpine:3.22 sh asciiverse/build-static.sh
# Leaves the binary at src/tt++.
set -eu

GNUTLS=3.8.13
# sha256 of gnutls-3.8.13.tar.xz; checked 2026-10-12 against Alpine's own
# APKBUILD (3.22-stable, sha512) for the same tarball.
GNUTLS_SHA256=ffed8ec1bf09c2426d4f14aae377de4753b53e537d685e604e99a8b16ca9c97e

apk add --no-cache build-base linux-headers curl xz \
  zlib-dev zlib-static zstd-dev zstd-static pcre2-dev pcre2-static \
  nettle-dev nettle-static gmp-dev gmp-static >/dev/null

work=$(mktemp -d)
curl -sSfL -o "$work/gnutls.tar.xz" "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-$GNUTLS.tar.xz"
echo "$GNUTLS_SHA256  $work/gnutls.tar.xz" | sha256sum -c -
tar -xJf "$work/gnutls.tar.xz" -C "$work"
(cd "$work/gnutls-$GNUTLS" &&
  ./configure --prefix=/opt/gnutls --enable-static --disable-shared \
    --with-included-libtasn1 --with-included-unistring --without-p11-kit \
    --without-idn --without-brotli --without-zstd --without-zlib --without-tpm --without-tpm2 \
    --disable-doc --disable-tests --disable-tools --disable-cxx --disable-nls \
    --disable-guile --disable-full-test-suite >/dev/null &&
  make -j"$(nproc)" >/dev/null && make install >/dev/null)

cd src
# configure finds GnuTLS through CPPFLAGS; the Makefile ignores configure's
# flags and appends to CFLAGS from the environment, so make gets it there
./configure CPPFLAGS="-I/opt/gnutls/include" LDFLAGS="-static -L/opt/gnutls/lib" \
  LIBS="-lgnutls -lhogweed -lnettle -lgmp" >/dev/null
grep -q "HAVE_GNUTLS_H 1" config.h
CFLAGS="-I/opt/gnutls/include" make -j"$(nproc)" >/dev/null
strip tt++
