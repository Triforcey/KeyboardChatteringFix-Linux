#!/usr/bin/env bash
# Builds the arm64 Debian package without dpkg-dev (uses ar + GNU tar).
set -euo pipefail

cd "$(dirname "$0")"

VERSION="${VERSION:-0.0.1}"
REVISION="${REVISION:-1}"
ARCH="${ARCH:-arm64}"
PKG="keyboard-chattering-fix"
DEB="${PKG}_${VERSION}-${REVISION}_${ARCH}.deb"

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

rootperm() { tar --owner=0 --group=0 --numeric-owner "$@"; }

# --- DEBIAN/control -------------------------------------------------------
mkdir -p "$stage/DEBIAN"
sed -e "s/@VERSION@/${VERSION}-${REVISION}/" -e "s/@ARCH@/${ARCH}/" \
    debian/control.in > "$stage/DEBIAN/control"
install -m 755 debian/postinst debian/prerm debian/postrm "$stage/DEBIAN/"

# --- data -----------------------------------------------------------------
data="$stage/data"
mkdir -p "$data/usr/lib/keyboard-chattering-fix" \
         "$data/usr/bin" \
         "$data/usr/lib/systemd/user"

# Original upstream tools/scripts, as-is.
cp -r src "$data/usr/lib/keyboard-chattering-fix/src"
cp chattering_fix.sh README.md LICENSE "$data/usr/lib/keyboard-chattering-fix/"
find "$data/usr/lib/keyboard-chattering-fix" -type f -exec chmod 644 {} +
find "$data/usr/lib/keyboard-chattering-fix" -type d -exec chmod 755 {} +
chmod 755 "$data/usr/lib/keyboard-chattering-fix/chattering_fix.sh"

# Fork-added helpers.
install -m 755 packaging/keyboard-debounce-run "$data/usr/bin/keyboard-debounce-run"
install -m 755 packaging/set-keyboard-debounce-target "$data/usr/bin/set-keyboard-debounce-target"
install -m 644 packaging/keyboard-debounce.service "$data/usr/lib/systemd/user/keyboard-debounce.service"

# --- assemble the .deb ----------------------------------------------------
( cd "$data" && rootperm -czf "$stage/data.tar.gz" . )
( cd "$stage/DEBIAN" && rootperm -czf "$stage/control.tar.gz" . )
printf '2.0\n' > "$stage/debian-binary"

rm -f "$DEB"
ar -r "$DEB" "$stage/debian-binary" "$stage/control.tar.gz" "$stage/data.tar.gz"

echo "Built: $DEB"
ar -t "$DEB"
