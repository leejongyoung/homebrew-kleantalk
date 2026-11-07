# homebrew-kleantalk

KleanTalk([leejongyoung/KleanTalk](https://github.com/leejongyoung/KleanTalk) fork) Homebrew 탭.

```sh
brew tap leejongyoung/kleantalk
brew install --cask kleantalk
```

제거:

```sh
brew uninstall --cask kleantalk
```

제거할 때 앱 안의 제거 스크립트가 서버·인증서 신뢰·hosts·로그인 항목을 되돌립니다.

## 새 릴리스 반영

fork에 새 릴리스가 올라오면 매일 03:00(KST) 워크플로가 Cask 갱신 PR을 엽니다. 수동 확인:

```sh
./update.sh --check   # 종료 코드 1 = 갱신 필요
./update.sh           # Casks/kleantalk.rb 갱신
```
