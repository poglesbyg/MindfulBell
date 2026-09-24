cask "stillpoint" do
  version "1.0"
  sha256 "e75b169e40c01060fa1b611922c79304e836f5001fb7e87aebd041f3aad967c9"

  url "https://github.com/poglesbyg/MindfulBell/releases/download/v#{version}/Stillpoint.zip"
  name "Stillpoint"
  desc "Meditation timer and mindfulness bell in the menu bar"
  homepage "https://poglesbyg.github.io/stillpoint/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "Stillpoint.app"

  uninstall quit:       "com.poglesbyg.mindfulbell",
            login_item: "Stillpoint"

  zap trash: "~/Library/Containers/com.poglesbyg.mindfulbell"

  caveats <<~EOS
    Stillpoint isn't notarized by Apple, so macOS blocks it the first time it opens.
    Open it once, click Done, then go to System Settings › Privacy & Security and
    click Open Anyway next to Stillpoint. You only need to do this once.
  EOS
end
