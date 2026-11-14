#!/bin/zsh
# fork 새 릴리스를 확인해 Cask 버전·SHA-256을 갱신한다.
# 사용: ./update.sh [--check] (--check: 0=최신, 1=갱신 필요, 2 이상=오류)
set -euo pipefail
cd "${0:A:h}"
if (( $# > 1 )) || [[ ${1:-} != "" && ${1:-} != --check ]]; then
  echo "usage: $0 [--check]" >&2
  exit 2
fi

REPO=leejongyoung/KleanTalk
CASK=Casks/kleantalk.rb
LATEST=$(gh release view --repo "$REPO" --json tagName --jq .tagName) || exit 2
VERSION=${LATEST#v}
if [[ ! $VERSION =~ '^[0-9][0-9A-Za-z.+-]*$' ]]; then
  echo "Invalid release version" >&2
  exit 2
fi
CURRENT=$(grep -m1 '^[[:space:]]*version "' "$CASK" | cut -d'"' -f2) || exit 2
if [[ -z $CURRENT ]]; then
  echo "Cannot read current Cask version" >&2
  exit 2
fi
if [[ $VERSION == "$CURRENT" ]]; then
  echo "최신: $VERSION"
  exit 0
fi
if [[ ${1:-} == --check ]]; then
  echo "갱신 필요: $CURRENT → $VERSION"
  exit 1
fi

TMP_DIR=$(mktemp -d)
DMG="$TMP_DIR/KleanTalk.dmg"
# Only this invocation's temporary download is removed.
trap 'rm -f -- "$DMG"; rmdir -- "$TMP_DIR"' EXIT
gh release download "$LATEST" --repo "$REPO" --pattern "KleanTalk.dmg" --dir "$TMP_DIR" >/dev/null || exit 2
SHA=$(shasum -a 256 "$DMG" | cut -d' ' -f1)
if [[ ! $SHA =~ '^[0-9a-f]{64}$' ]]; then
  echo "Cannot calculate release checksum" >&2
  exit 2
fi
sed -i '' "s/^[[:space:]]*version \".*\"/  version \"$VERSION\"/" "$CASK"
sed -i '' "s/^[[:space:]]*sha256 \".*\"/  sha256 \"$SHA\"/" "$CASK"
if ! grep -Fqx "  version \"$VERSION\"" "$CASK" || ! grep -Fqx "  sha256 \"$SHA\"" "$CASK"; then
  echo "Cask update verification failed" >&2
  exit 2
fi
echo "갱신: $CURRENT → $VERSION ($SHA)"
