#!/usr/bin/env bash
# Re-fetches FDM's rolling /latest/ .deb, reads its real version out of the
# package's own control metadata, computes the new Nix hash, and rewrites
# freedownloadmanager.nix in place. Designed to be run from CI, but safe to
# run locally too.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
NIX_FILE="${REPO_ROOT}/freedownloadmanager.nix"
URL="https://files2.freedownloadmanager.org/6/latest/freedownloadmanager.deb"

if [[ ! -f "$NIX_FILE" ]]; then
  echo "Could not find $NIX_FILE" >&2
  exit 1
fi

echo "Prefetching $URL ..."
# nix-prefetch-url downloads once into the Nix store and gives us a hash;
# we then read the version out of that same store path via dpkg-deb, so we
# never have to download the .deb twice.
PREFETCH_OUT="$(nix-prefetch-url --type sha256 --print-path "$URL")"
OLD_STYLE_HASH="$(echo "$PREFETCH_OUT" | head -n1)"
STORE_PATH="$(echo "$PREFETCH_OUT" | tail -n1)"

NEW_HASH="$(nix hash to-sri --type sha256 "$OLD_STYLE_HASH")"
NEW_VERSION="$(dpkg-deb -f "$STORE_PATH" Version)"

CURRENT_VERSION="$(grep -oP '(?<=version = ")[^"]+' "$NIX_FILE" | head -n1)"
CURRENT_HASH="$(grep -oP '(?<=hash = ")[^"]+' "$NIX_FILE" | head -n1)"

echo "Current: version=$CURRENT_VERSION hash=$CURRENT_HASH"
echo "Latest:  version=$NEW_VERSION hash=$NEW_HASH"

if [[ "$NEW_VERSION" == "$CURRENT_VERSION" && "$NEW_HASH" == "$CURRENT_HASH" ]]; then
  echo "Already up to date."
  echo "changed=false" >> "${GITHUB_OUTPUT:-/dev/null}"
  exit 0
fi

sed -i "s|version = \"${CURRENT_VERSION}\";|version = \"${NEW_VERSION}\";|" "$NIX_FILE"
sed -i "s|hash = \"${CURRENT_HASH}\";|hash = \"${NEW_HASH}\";|" "$NIX_FILE"

echo "Updated $NIX_FILE to version $NEW_VERSION."
{
  echo "changed=true"
  echo "old_version=$CURRENT_VERSION"
  echo "new_version=$NEW_VERSION"
} >> "${GITHUB_OUTPUT:-/dev/null}"
