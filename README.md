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

```bash
git clone <this-repo> agent-debate
cd agent-debate
bash install.sh
source ~/.zshrc

debate doctor          # 의존성 점검
debate start           # 세션 시작
```

human pane(`moderator`)에서:

```bash
debate tell a "API 500 에러를 'DB 풀 고갈' 가설로 분석해"
debate tell b "동일 에러를 '레이스 컨디션' 가설로 분석해"
debate round 3 rebut 20 --sum   # 3라운드 자동 토론 (요약 모드)
debate verdict                  # arbiter 에게 판정 요청
debate hear arbiter 100
```

## 기능

- **mode 분화 릴레이** — `rebut` / `review` / `agree` / `extend` / `question` / `judge`
- **요약 후 릴레이** — 화자에게 먼저 요약시킨 뒤 깔끔하게 전달
- **자동 N라운드** — `debate round 3 review --sum`
- **중재자 판정** — `debate verdict` 한 줄
- **자동 로그** — `~/.debate/log-YYYYMMDD.md` 에 모든 호출 기록
- **zsh 자동완성** — 서브커맨드/mode/target 모두 한글 설명과 함께
- **CLI 자유 선택** — `--a claude --b cursor` 등 양쪽을 임의 조합
- **pane 상단 타이틀바** — `A: claude`, `B: cursor` 굵게 표시 (활성 pane cyan)

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

## 라이선스

MIT
