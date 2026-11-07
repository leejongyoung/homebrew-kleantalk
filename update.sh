#!/bin/zsh
# fork 새 릴리스를 확인해 Cask 버전·SHA-256을 갱신한다.
# 사용: ./update.sh [--check]   (--check는 확인만, 종료 코드 1 = 갱신 필요)
#cron 워크플로(.github/workflows/update-cask.yml)가 매일 돌린다.
cd "${0:A:h}"

REPO=leejongyoung/KleanTalk
CASK=Casks/kleantalk.rb
LATEST=$(gh release view --repo "$REPO" --json tagName --jq .tagName)
VERSION=${LATEST#v}

CURRENT=$(grep -m1 '^\s*version "' "$CASK" | cut -d'"' -f2)
if [[ $VERSION == "$CURRENT" ]]; then
  echo "최신: $VERSION"
  [[ ${1:-} == --check ]] && exit 1 || exit 0
fi

DMG=$(mktemp -d)/KleanTalk.dmg
gh release download "$LATEST" --repo "$REPO" --pattern "KleanTalk.dmg" --dir "${DMG:h}" --clobber >/dev/null
mv "${DMG:h}/KleanTalk.dmg" "$DMG"
SHA=$(shasum -a 256 "$DMG" | cut -d' ' -f1)
rm -f "$DMG"
sed -i '' "s/^\s*version \".*\"/  version \"$VERSION\"/" "$CASK"
sed -i '' "s/^\s*sha256 \".*\"/  sha256 \"$SHA\"/" "$CASK"
echo "갱신: $CURRENT → $VERSION ($SHA)"
