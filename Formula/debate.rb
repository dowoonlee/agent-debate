class Debate < Formula
  desc "AI 코딩 에이전트 두 명을 tmux 안에서 토론시키는 단일 CLI"
  homepage "https://github.com/dowoonlee/agent-debate"
  url "https://github.com/dowoonlee/agent-debate/archive/refs/tags/v0.4.2.tar.gz"
  sha256 "86ed1fbc246c9d7ad26818857aa8132b7efc89f05a245f185c71e3709fed4349"
  license "MIT"
  version "0.4.2"
  head "https://github.com/dowoonlee/agent-debate.git", branch: "master"

  depends_on "tmux"
  # smux (tmux-bridge) 는 brew 에 없으므로 caveats 로 안내
  # 사용자가 직접 설치하거나 install.sh 가 자동 설치

  def install
    bin.install "bin/debate"
    zsh_completion.install "completions/_debate"
  end

  def caveats
    <<~EOS
      debate 는 smux (tmux-bridge) 와 Claude Code / Cursor CLI 가 필요합니다.

        # smux
        curl -fsSL https://raw.githubusercontent.com/ShawnPana/smux/main/install.sh | bash
        echo 'export PATH="$HOME/.smux/bin:$PATH"' >> ~/.zshrc

        # Claude Code
        npm install -g @anthropic-ai/claude-code

        # Cursor CLI
        curl https://cursor.com/install -fsS | bash

      설치 후 점검:
        debate doctor

      자동완성을 위해 ~/.zshrc 에 다음을 추가하세요:
        autoload -Uz compinit && compinit
    EOS
  end

  test do
    assert_match "debate", shell_output("#{bin}/debate help")
  end
end
