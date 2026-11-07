cask "kleantalk" do
  version "1.11.2"
  sha256 "8940e616a29d73cb2c02ed0692399ef5038f4411ad1176f0e30f87ddc2ff5cc7"

  url "https://github.com/leejongyoung/KleanTalk/releases/download/v#{version}/KleanTalk.dmg"
  name "KleanTalk"
  desc "맥 카카오톡 하단 광고를 빈 공간으로 바꾸는 무료 오픈소스 앱"
  homepage "https://github.com/leejongyoung/KleanTalk"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "KleanTalk.app"

  uninstall quit:   "com.myungchul.kleantalk",
            script: {
              executable: "#{appdir}/KleanTalk.app/Contents/Resources/uninstall-adserver.sh",
              sudo:       true,
            }

  caveats <<~EOS
    처음 실행하면 macOS가 "악성 코드가 없음을 확인할 수 없습니다"라고 합니다.
    시스템 설정 → 개인정보 보호 및 보안 → 그래도 열기를 누르세요.
  EOS
end
