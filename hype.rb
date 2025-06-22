# Homebrew formula for Hype
class Hype < Formula
  desc "Lua Script to Executable Packager with TUI, HTTP, and Database support"
  homepage "https://github.com/twilson63/hype"
  version "1.0.1"

  if Hardware::CPU.intel?
    url "https://github.com/twilson63/hype/releases/download/v#{version}/hype-darwin-amd64"
    sha256 "calculate-sha256-for-intel-binary"
  else
    url "https://github.com/twilson63/hype/releases/download/v#{version}/hype-darwin-arm64"
    sha256 "calculate-sha256-for-arm-binary"
  end

  def install
    bin.install Dir["hype-darwin-*"].first => "hype"
  end

  test do
    system "#{bin}/hype", "--help"
  end
end