#!/bin/sh
set -eu

version=3.2
archive="gnucobol-${version}.tar.xz"
url="https://ftp.gnu.org/gnu/gnucobol/${archive}"
sha=3bb48af46ced4779facf41fdc2ee60e4ccb86eaa99d010b36685315df39c2ee2
data_root=${XDG_DATA_HOME:-"$HOME/.local/share"}
prefix="$data_root/cobollm/gnucobol-${version}"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT HUP INT TERM

curl -L --fail --silent --show-error -o "$work/$archive" "$url"
printf '%s  %s\n' "$sha" "$work/$archive" | sha256sum -c -
tar -C "$work" -xf "$work/$archive"
cd "$work/gnucobol-${version}"
./configure --prefix="$prefix" --without-db
make
make install

printf 'export COBC=%s/bin/cobc\n' "$prefix"
printf 'export PATH=%s/bin:$PATH\n' "$prefix"
