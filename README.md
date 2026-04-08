# debate

> AI 코딩 에이전트 두 명을 tmux 안에서 토론시키고, 제3의 에이전트가 중재·판정하는 단일 CLI

Claude Code, Cursor CLI Agent 같은 CLI 기반 코딩 에이전트를 4-pane tmux 레이아웃에 띄워, 사람이 진행자(moderator) 자리에서 `debate` 명령 한 줄로 양쪽 토론자(`a`/`b`)를 조율하고, 중재자(`arbiter`)에게 판정을 받습니다.

```
┌── A: claude ───┬── B: cursor ───┐
│                │                │
│                │                │
├──── ARBITER: claude (wide) ─────┤
├──── MODERATOR (wide) ───────────┤
```

## 빠른 시작

### Homebrew (권장)

```bash
brew install dowoonlee/debate/debate
debate doctor
debate install-hooks    # HITL 자동 focus (1회 설정)
debate start
```

### 직접 설치

```bash
git clone https://github.com/dowoonlee/agent-debate.git
cd agent-debate
bash install.sh
source ~/.zshrc

debate doctor
debate start
```

moderator pane 에서:

```bash
debate tell a "API 500 에러를 'DB 풀 고갈' 가설로 분석해"
debate tell b "동일 에러를 '레이스 컨디션' 가설로 분석해"
debate round 3 rebut 20 --sum    # 3라운드 자동 토론 (요약 모드)
debate verdict                   # arbiter 에게 판정 요청
debate hear arbiter 100

debate save auth-bug             # debate-<uuid> → debate-auth-bug 로 rename
debate stop                      # 종료 (dir 은 보존)
# 나중에:
debate resume debate-auth-bug    # native --resume 으로 컨텍스트 복원
```

여러 debate를 동시에 띄우려면:

```bash
debate start --name auth --topic "auth bug"   # 터미널 1
debate start --name perf --topic "slow API"   # 터미널 2

debate ls                                     # 어디서든 전체 확인
#   debate-perf     running*   ...   slow API
#   debate-auth     running    ...   auth bug
```

## 기능

### 토론 진행
- **mode 분화 릴레이** — `rebut` / `review` / `agree` / `extend` / `question` / `judge`
- **독립 세션 요약 릴레이** (`relay-sum`) — pane 출력을 캡처해서 `claude --print` 로 요약 후 전달. 화자 컨텍스트 오염 없음 (v0.4.2)
- **prompt append** — `relay`/`relay-sum` 마지막 인자에 `"추가 지시"` 넣으면 prompt 뒤에 newline 으로 붙음 (v0.4.1)
- **자동 N라운드** — `debate round 3 review --sum`
- **중재자 판정** (`verdict`) — A/B 출력을 모아 arbiter 에게 판정 요청
- **인터랙티브 mode 선택** (`pick`) — fzf/select 메뉴로 mode 고르기

### HITL 자동 focus (v0.4.0)
- **자동 pane focus** — claude/cursor 가 권한 요청·입력 대기 시 해당 pane으로 자동 focus 이동, 답변 제출 후 moderator 로 자동 복귀
- **claude hooks** — `Notification (permission_prompt|idle_prompt)` → focus pane, `UserPromptSubmit` → focus moderator
- **cursor hooks** — `stop` → focus pane, `beforeSubmitPrompt` → focus moderator
- **안전한 머지** — `~/.claude/settings.json` / `~/.cursor/hooks.json` 의 기존 hook 을 보존, marker 기반 install/uninstall
- **수동 키바인딩** — `prefix + a/b/r/m` 으로 즉시 pane 이동 (debate start 시 자동 등록)
- 활성화: `debate install-hooks` (1회), 제거: `debate uninstall-hooks`

### 다중 세션 (v0.3.0)
- **세션 id 자동 생성** — 매 `debate start` 가 `debate-<8자리 uuid>` 를 자동 발급. `--name <foo>` 로 의미있는 이름도 가능 (`debate-foo`)
- **여러 debate 동시 실행** — 각 세션은 고유 tmux 세션 + 저장 dir 로 격리
- **자동 인식** — moderator pane 안에서 친 명령은 `$TMUX` 로 자기 세션 자동 인식. 두 debate 가 떠 있어도 충돌 없음
- **외부 호출** — `~/.debate/active` 가 마지막 시작한 세션을 기본값으로. `DEBATE_SESSION=debate-foo debate hear a` 로 명시도 가능
- **`debate ls`** — 전체 세션 목록 + `running` / `active*` 표시
- **`debate attach <name>`** — 실행 중인 세션에 들어가기

### 세션 저장 & 복원 (v0.2.0+)
- **Native session resume** — claude `--session-id` / cursor `agent create-chat` 으로 ID 직접 발급, `--resume` 으로 실제 LLM 컨텍스트 복원
- **자동 보존** — `debate stop` 후에도 dir 보존. 자동 생성 uuid 세션은 `DEBATE_AUTO_KEEP` (기본 10) 만큼만 유지하고 회전 (`--name` 명시 세션은 보존)
- **rename 저장** — `debate save <new-name>` 으로 활성 세션을 의미있는 이름으로 rename (dir + tmux 세션 + active 포인터 동시 갱신)
- **복원** — `debate resume <name>` 으로 동일한 4-pane 레이아웃 + 컨텍스트 복원
- **분기** — `debate fork <name>` (claude `--fork-session`, cursor 새 chatId, 새 dir)
- **export/import** — `debate export <name> <out.tar.gz>` 로 다른 머신 이전

### 운영 편의
- **자동 로그** — 모든 호출이 `~/.debate/log-YYYYMMDD.md` 에 기록
- **zsh 자동완성** — 서브커맨드 / mode / target / 저장된 세션 이름까지 한글 설명과 함께
- **CLI 자유 선택** — `--a claude --b cursor` 등 양쪽을 임의 조합
- **pane 상단 타이틀바** — `A: claude`, `B: cursor` 굵게 표시 (활성 pane cyan)
- **base-index 안전** — pane id 기반 레이아웃으로 `pane-base-index` 설정과 무관하게 동작

## 의존성

| | |
|---|---|
| tmux 2.3+ | PTY 멀티플렉서 (필수) |
| [smux](https://github.com/ShawnPana/smux) | tmux pane 외부 read/write (`install.sh` 자동 설치) |
| [Claude Code](https://code.claude.com) | 에이전트 |
| [Cursor CLI](https://cursor.com/cli) | 에이전트 |
| fzf (선택) | `debate pick` 인터랙티브 메뉴 |

> Cursor CLI Agent 는 진짜 TTY 가 필요해서 일반 셸에서 hang 됩니다. tmux + smux 조합이 이를 해결합니다.

## 프로젝트 구조

```
agent-debate/
├── bin/debate              # 단일 실행 CLI
├── completions/_debate     # zsh 자동완성
├── install.sh              # 설치 스크립트
├── debate-setup-guide.md   # 상세 가이드
└── README.md
```

## 문서

- 상세 사용법, 명령어 치트시트, 실전 예시, 트러블슈팅 → [debate-setup-guide.md](./debate-setup-guide.md)
- `debate help` 로 CLI 내장 도움말

## 환경변수

| | |
|---|---|
| `DEBATE_LOG` | 로그 파일 경로 (기본 `~/.debate/log-YYYYMMDD.md`) |
| `DEBATE_SESSION` | tmux 세션 이름 (기본 `debate`) |
| `DEBATE_A_CMD` | A pane 기본 CLI (기본 `claude`) |
| `DEBATE_B_CMD` | B pane 기본 CLI (기본 `cursor`) |
| `DEBATE_ARBITER_CMD` | arbiter pane 기본 CLI (기본 `claude`) |
| `DEBATE_SESSIONS_DIR` | 세션 저장 디렉토리 (기본 `~/.debate/sessions`) |
| `DEBATE_AUTO_KEEP` | 자동 보존 세션 최대 개수 (기본 10) |
| `DEBATE_SUMMARIZER` | `relay-sum` 의 독립 요약기 (`claude` \| `cursor`, 기본 `claude`) |

## 라이선스

MIT
