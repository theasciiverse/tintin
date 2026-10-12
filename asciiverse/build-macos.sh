#!/bin/sh
# Builds TinTin++ (tt++) on macOS with no libraries beyond the system's own:
# gmp, nettle and pcre2 come from Homebrew as static archives, GnuTLS is
# built from its release tarball like the Linux build (build-static.sh).
# Run from the repository root on a macOS runner. Leaves src/tt++.
set -eu

GNUTLS=3.8.13
GNUTLS_SHA256=ffed8ec1bf09c2426d4f14aae377de4753b53e537d685e604e99a8b16ca9c97e

brew install gmp nettle pcre2 >/dev/null
# a folder holding only the static archives, searched first, so the linker
# takes them instead of Homebrew's dylibs
static="$PWD/.static-libs"; mkdir -p "$static"
for f in "$(brew --prefix gmp)/lib/libgmp.a" "$(brew --prefix nettle)/lib/libnettle.a" \
         "$(brew --prefix nettle)/lib/libhogweed.a" "$(brew --prefix pcre2)/lib/libpcre2-8.a"; do
  ln -sf "$f" "$static/"
done

work=$(mktemp -d)
curl -sSfL -o "$work/gnutls.tar.xz" "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-$GNUTLS.tar.xz"
echo "$GNUTLS_SHA256  $work/gnutls.tar.xz" | shasum -a 256 -c -
tar -xJf "$work/gnutls.tar.xz" -C "$work"
# CRAU_MAYBE_UNUSED: GnuTLS 3.8.13's lib/crau/crau.h picks C23 [[maybe_unused]]
# when clang reports it, then puts it where clang's default C mode rejects
# it; the header leaves the macro alone when it is already defined.
inc="-I$(brew --prefix gmp)/include -I$(brew --prefix nettle)/include -DCRAU_MAYBE_UNUSED="
(cd "$work/gnutls-$GNUTLS" &&
  ./configure --prefix="$work/gnutls" --enable-static --disable-shared \
    CPPFLAGS="$inc" LDFLAGS="-L$static" \
    NETTLE_CFLAGS="-I$(brew --prefix nettle)/include" NETTLE_LIBS="-L$static -lnettle" \
    HOGWEED_CFLAGS="-I$(brew --prefix nettle)/include" HOGWEED_LIBS="-L$static -lhogweed" \
    GMP_CFLAGS="-I$(brew --prefix gmp)/include" GMP_LIBS="-L$static -lgmp" \
    --with-included-libtasn1 --with-included-unistring --without-p11-kit \
    --without-idn --without-brotli --without-zstd --without-zlib --without-tpm --without-tpm2 \
    --disable-doc --disable-tests --disable-tools --disable-cxx --disable-nls \
    --disable-guile --disable-full-test-suite >/dev/null &&
  make -j"$(sysctl -n hw.ncpu)" >/dev/null && make install >/dev/null)
ln -sf "$work/gnutls/lib/libgnutls.a" "$static/"

cd src
./configure CPPFLAGS="-I$work/gnutls/include -I$(brew --prefix pcre2)/include" \
  LDFLAGS="-L$static" LIBS="-lgnutls -lhogweed -lnettle -lgmp -framework Security -framework CoreFoundation" >/dev/null
grep -q "HAVE_GNUTLS_H 1" config.h
CFLAGS="-I$work/gnutls/include -I$(brew --prefix pcre2)/include" make -j"$(sysctl -n hw.ncpu)" >/dev/null
strip tt++
# nothing but the system's own libraries may remain
otool -L tt++
if otool -L tt++ | tail -n +2 | grep -v -E "^\s*/(usr/lib|System/Library)/"; then
  echo "tt++ links a library outside the system" >&2; exit 1
fi
