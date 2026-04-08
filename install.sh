#!/usr/bin/env bash
# install.sh — debate CLI 설치
# Usage: bash install.sh
set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_SRC="$SCRIPT_DIR/bin/debate"
COMP_SRC="$SCRIPT_DIR/completions/_debate"
BIN_DST="$HOME/.local/bin/debate"
COMP_DST="$HOME/.zsh/completions/_debate"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║   debate CLI 설치                           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ─── 1. tmux ────────────────────────────────────────────
if command -v tmux &>/dev/null; then
  info "tmux: $(tmux -V)"
else
  warn "tmux 미설치 — brew install tmux 또는 패키지 매니저로 설치하세요"
fi

# ─── 2. smux (tmux-bridge) ──────────────────────────────
if command -v tmux-bridge &>/dev/null; then
  info "smux 이미 설치됨"
else
  warn "smux 설치 중..."
  if curl -fsSL https://raw.githubusercontent.com/ShawnPana/smux/main/install.sh | bash; then
    info "smux 설치 완료"
  else
    git clone https://github.com/ShawnPana/smux.git /tmp/smux-install 2>/dev/null
    bash /tmp/smux-install/install.sh
    rm -rf /tmp/smux-install
    info "smux 설치 완료 (git clone)"
  fi
fi

# ─── 3. debate CLI 배치 ─────────────────────────────────
mkdir -p "$(dirname "$BIN_DST")"
install -m 0755 "$BIN_SRC" "$BIN_DST"
info "installed: $BIN_DST"

# ─── 4. zsh 자동완성 ────────────────────────────────────
if [ -f "$COMP_SRC" ]; then
  mkdir -p "$(dirname "$COMP_DST")"
  install -m 0644 "$COMP_SRC" "$COMP_DST"
  info "installed: $COMP_DST"
fi

# ─── 5. PATH / fpath 안내 ───────────────────────────────
echo ""
NEED_PATH=0
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) NEED_PATH=1 ;;
esac

if [ "$NEED_PATH" = "1" ] || ! grep -q "zsh/completions" "$HOME/.zshrc" 2>/dev/null; then
  echo "── ~/.zshrc 에 다음을 추가하세요 ─────────────"
  [ "$NEED_PATH" = "1" ] && echo '  export PATH="$HOME/.local/bin:$PATH"'
  echo '  fpath=($HOME/.zsh/completions $fpath)'
  echo '  autoload -Uz compinit && compinit'
  echo "─────────────────────────────────────────────"
  echo ""
fi

# ─── 6. 의존성 점검 ─────────────────────────────────────
echo "── 의존성 점검 ────────────────────────────────"
command -v claude  &>/dev/null && info "claude: $(claude --version 2>/dev/null || echo ok)" \
  || err "claude 미설치 → npm install -g @anthropic-ai/claude-code"
( command -v agent &>/dev/null || command -v cursor-agent &>/dev/null ) \
  && info "cursor agent: ok" \
  || err "cursor agent 미설치 → curl https://cursor.com/install -fsS | bash"
command -v tmux-bridge &>/dev/null && info "tmux-bridge: ok" \
  || err "tmux-bridge 미설치"

echo ""
info "설치 완료 — 사용:"
echo "    source ~/.zshrc"
echo "    debate help"
echo "    debate doctor"
echo "    debate start"
echo ""
