# debate CLI — AI 에이전트 토론 셋업 가이드

> **smux** + **debate CLI** 로 두 AI 코딩 에이전트(claude/cursor 등)를 tmux 안에서 토론시키고, 제3의 에이전트가 중재·판정하는 워크플로우

---

## 개요

4-pane tmux 레이아웃:

```
┌── A: claude ───┬── B: cursor ───┐   ← debater (자유 선택)
│                │                │
│                │                │
├──── ARBITER: claude (wide) ─────┤   ← 중재자/판정자
├──── MODERATOR (wide) ───────────┤   ← 사용자 (debate CLI 실행)
```

각 pane 상단에는 `A: claude`, `B: cursor`, `ARBITER: claude` 같은 굵은 타이틀바가 표시됩니다 (활성 pane은 cyan 강조).

---

## 역할

| pane label | 역할 | 기본 CLI |
|------------|------|---------|
| `a` | 토론자 A | `claude` |
| `b` | 토론자 B | `cursor` |
| `arbiter` | 중재자/판정자 | `claude` |
| `moderator` | 사용자 (이 CLI 실행) | (직접 입력) |

각 토론자/중재자가 어떤 CLI 를 띄울지 자유롭게 선택할 수 있습니다:
- `--a`, `--b`, `--arbiter` 플래그
- 환경변수 `DEBATE_A_CMD`, `DEBATE_B_CMD`, `DEBATE_ARBITER_CMD`
- alias 자동 변환: `cursor` → `agent` (Cursor CLI 실제 명령어)

---

## 1. 사전 요구사항

| 도구 | 역할 | 설치 |
|------|------|------|
| tmux | PTY 멀티플렉서 (필수) | `brew install tmux` |
| smux (`tmux-bridge`) | tmux pane 외부 read/write | `install.sh` 자동 처리 |
| Claude Code | 에이전트 | `npm i -g @anthropic-ai/claude-code` |
| Cursor CLI Agent | 에이전트 | `curl https://cursor.com/install -fsS \| bash` |
| fzf (선택) | `debate pick` 인터랙티브 메뉴 | `brew install fzf` |

> **왜 tmux가 필수인가**: Cursor CLI Agent는 진짜 TTY가 없으면 hang됩니다. tmux pane이 PTY를 제공하고, smux의 `tmux-bridge`가 그 pane을 외부에서 read/type할 수 있게 해줍니다.

---

## 2. 설치

```bash
git clone <this-repo> agent-debate
cd agent-debate
bash install.sh
source ~/.zshrc
debate doctor
```

`install.sh` 가 하는 일:
1. tmux 확인
2. smux 자동 설치
3. `bin/debate` → `~/.local/bin/debate` 복사
4. `completions/_debate` → `~/.zsh/completions/_debate` 복사
5. PATH/fpath 안내
6. 의존성 점검

`~/.zshrc` 에 아래가 없으면 추가:

```bash
export PATH="$HOME/.local/bin:$PATH"
fpath=($HOME/.zsh/completions $fpath)
autoload -Uz compinit && compinit
```

---

## 3. 사용법

### 세션 시작 / 종료

```bash
debate start                                  # 기본: A=claude, B=cursor, arbiter=claude
debate start --a claude --b cursor            # 명시
debate start --a claude --b claude            # claude vs claude
debate start --a cursor --b cursor            # cursor vs cursor
debate start --arbiter cursor                 # 중재자만 cursor 로
debate start ~/my-project                     # 다른 디렉토리
debate stop
```

### 메시지 입력 / 출력 캡처

```bash
debate tell a "API 500 에러를 분석해. 'DB 풀 고갈' 가설을 주장해."
debate tell b "동일 에러를 분석해. '레이스 컨디션' 가설을 주장해."

debate hear a            # 30줄 (기본)
debate hear b 100        # 100줄
debate hear arbiter 50
```

### 릴레이 (mode 분화)

```bash
debate relay a b               # rebut (기본, 반론)
debate relay a b review        # 코드 검토·약점 지적
debate relay a b agree         # 동의+보완
debate relay a b extend        # 가설 발전·증거 보강
debate relay a b question      # 날카로운 질문 3개
debate relay a b judge         # 중립 판정
```

| mode | 동작 |
|------|------|
| `rebut` | 상대 주장에 반론 (기본) |
| `review` | 코드 관점에서 누락/오류/약점 지적 |
| `agree` | 동의 부분 + 보완점 정리 |
| `extend` | 가설을 발전시키고 추가 증거 탐색 |
| `question` | 명확하지 않은 부분에 질문 3개 |
| `judge` | 중립 판정 |

### 요약 후 릴레이

화자에게 먼저 자기 주장을 5~7줄로 요약시키고, 그 요약만 상대에 전달:

```bash
debate relay-sum a b              # rebut, 요약 대기 10초
debate relay-sum a b review 15    # review, 요약 대기 15초
```

### N 라운드 자동 진행

```bash
debate round 3                              # rebut 3라운드 (a↔b 교대)
debate round 5 review 20                    # review 5라운드, 라운드 사이 20초
debate round 3 rebut 15 --sum               # 매 릴레이마다 요약 후 전달
```

### 양쪽 동시 지시

```bash
debate shout "지금까지 토론을 종합해서 최종 결론과 수정 방안을 정리해."
debate shout --all "위 토론을 정리해"        # arbiter 도 포함
```

### 중재자 판정 (verdict)

`a` 와 `b` 의 최근 출력을 모아 `arbiter` 에 판정 요청:

```bash
debate verdict           # 최근 40줄씩
debate verdict 80        # 최근 80줄씩
```

### 인터랙티브 mode 선택

```bash
debate pick a b
# fzf 가 있으면 fzf 메뉴, 없으면 select 메뉴
```

### HITL 자동 focus (v0.4.0)

claude/cursor 가 사용자 입력을 기다릴 때 자동으로 그 pane 으로 focus 가 이동하고, 답변 후 moderator pane 으로 돌아옵니다. claude/cursor 의 native hook 시스템을 사용합니다.

```bash
# 최초 1회 설치
debate install-hooks

# 상태 확인
debate hooks-status
#   [✓] claude: installed → Notification, UserPromptSubmit
#   [✓] cursor: installed → stop, beforeSubmitPrompt

# 제거
debate uninstall-hooks
```

설치되는 hook:

| CLI | 이벤트 | 동작 |
|-----|--------|------|
| claude | `Notification (permission_prompt\|idle_prompt)` | 해당 pane focus |
| claude | `UserPromptSubmit` | moderator focus |
| cursor | `stop` | 해당 pane focus |
| cursor | `beforeSubmitPrompt` | moderator focus |

설치는 marker 기반(`# debate-managed`)이라 기존 hook 과 충돌하지 않고 `uninstall-hooks` 로 깔끔히 제거됩니다.

### 수동 key bindings

`debate start` 시 tmux 키바인딩이 자동 등록됩니다 (prefix = `Ctrl+b` 기본):

| 키 | 동작 |
|----|------|
| `prefix + a` | A pane focus |
| `prefix + b` | B pane focus |
| `prefix + r` | arbiter focus |
| `prefix + m` | moderator focus |

또는 명시 명령:

```bash
debate focus a
debate focus moderator
```

### 다중 세션 (v0.3.0)

각 `debate start` 는 고유 세션 id (`debate-<8자리 uuid>`) 를 자동 발급합니다. `--name` 으로 의미있는 이름도 부여 가능.

```bash
# 자동 uuid
debate start --topic "auth bug"
# → debate-7f3a1b2c

# 의미있는 이름
debate start --name perf --topic "slow API"
# → debate-perf

# 동시에 두 개 (다른 터미널)
debate start --name auth     # 터미널 1
debate start --name perf     # 터미널 2

# 어디서든 전체 보기
debate ls
#   NAME            STATE      CREATED          TOPIC
#   debate-perf     running*   2026-04-08...   slow API
#   debate-auth     running    2026-04-08...   auth bug
#   debate-3e2a8b91            2026-04-07...   (older, stopped)
#
# (* = active default; running = tmux 세션 살아있음)

# 실행 중인 세션 attach
debate attach debate-auth

# 종료 (dir 은 보존)
debate stop                  # active 세션 종료
debate stop debate-perf      # 명시 지정
```

**자동 인식**: moderator pane 안에서 친 명령은 `$TMUX` 환경변수로 그 세션을 자동 인식합니다. 두 debate 가 떠 있어도 각자의 moderator 에서 친 `tell`/`hear`/`relay` 등은 자기 쪽에만 영향을 줍니다.

**외부 호출**: moderator pane 밖에서 호출 시에는 `~/.debate/active` 의 마지막 시작한 세션이 기본값입니다. 명시 지정하려면:

```bash
DEBATE_SESSION=debate-perf debate hear a
```

### 세션 저장 / 복원

각 pane 의 native session id (claude `--session-id`, cursor `agent create-chat`) 를 자동 발급/저장해서 나중에 그대로 복원합니다.

```bash
# 활성 세션을 의미있는 이름으로 rename
# (debate-7f3a1b2c → debate-auth-bug, dir + tmux + active 모두 갱신)
debate save auth-bug

# 종료 (dir 은 그대로 남음)
debate stop

# 메타데이터 미리보기
debate show debate-auth-bug

# 복원 — 각 에이전트가 native --resume 으로 이전 LLM 컨텍스트 그대로
debate resume debate-auth-bug

# 다른 디렉토리에서 복원
debate resume debate-auth-bug --in ~/another-clone

# arbiter 까지 복원 (기본은 fresh)
debate resume debate-auth-bug --include-arbiter

# 분기 — claude --fork-session, cursor 새 chatId, 새 dir 생성
debate fork debate-auth-bug

# 삭제 (running 이면 같이 kill) / 내보내기
debate forget debate-auth-bug
debate export debate-auth-bug ~/backup.tar.gz
```

복원 동작:
- A pane: claude 면 `claude --resume <uuid>`, cursor 면 `agent --resume <chatId>`
- B pane: 동일 방식
- arbiter: 기본 fresh (`--include-arbiter` 시에만 복원)
- 4-pane 레이아웃 자동 재구성, MODERATOR 타이틀에 세션 id 표시

저장 위치: `~/.debate/sessions/<id>/meta` (환경변수 `DEBATE_SESSIONS_DIR` 로 변경)
회전: `--name` 없이 자동 생성된 `debate-<8자리 uuid>` 만 회전 대상 (최근 `DEBATE_AUTO_KEEP` 개 유지, 기본 10). `--name` 명시 세션은 영구 보존.

### 로그

모든 호출은 자동 기록됩니다:

```bash
debate log                  # $EDITOR / less
debate log tail 50          # 최근 50줄
debate log path             # 로그 파일 경로
debate log clear            # 비우기
```

기본 경로: `~/.debate/log-YYYYMMDD.md` (`$DEBATE_LOG` 로 변경)

### 자동완성

`debate <Tab>`, `debate relay a b <Tab>` 등에서 서브커맨드와 mode 후보가 한글 설명과 함께 자동완성됩니다. target 자리에는 `a/b/arbiter/moderator` 가 후보로 뜹니다.

---

## 4. pane 직접 이동

| 키 | 이동 |
|----|------|
| `Option+i` | 위쪽 pane |
| `Option+k` | 아래쪽 pane |
| `Option+j` | 왼쪽 pane |
| `Option+l` | 오른쪽 pane |

마우스 클릭으로도 가능합니다.

---

## 5. 명령어 치트시트

| 명령 | 설명 |
|------|------|
| `debate start [--a CMD] [--b CMD] [--arbiter CMD] [dir]` | 세션 시작 |
| `debate stop` | 세션 종료 |
| `debate doctor` | 의존성 점검 |
| `debate tell <a\|b\|arbiter> <msg>` | 메시지 입력 + Enter |
| `debate hear <target> [N]` | 출력 N줄 캡처 |
| `debate relay <from> <to> [mode] [lines]` | 출력 캡처 후 전달 |
| `debate relay-sum <from> <to> [mode] [wait]` | 요약 시킨 뒤 전달 |
| `debate round N [mode] [wait] [--sum]` | N라운드 자동 양방향 릴레이 |
| `debate pick <from> <to>` | mode 메뉴 선택 후 relay |
| `debate shout [--all] <msg>` | 양쪽 토론자 동시 지시 |
| `debate verdict [lines]` | a+b 출력을 arbiter 에 판정 요청 |
| `debate focus <a\|b\|arbiter\|moderator>` | 특정 pane 으로 focus 이동 |
| `debate install-hooks` | HITL 자동 focus hook 설치 |
| `debate uninstall-hooks` | hook 제거 |
| `debate hooks-status` | hook 설치 상태 확인 |
| `debate attach [name]` | 실행 중인 세션 attach |
| `debate save <new-name>` | 활성 세션을 debate-<new-name> 으로 rename |
| `debate list` | 모든 세션 목록 (running / active*) |
| `debate show [name]` | 세션 메타+로그 미리보기 |
| `debate resume <name> [--include-arbiter] [--in dir]` | native resume 복원 |
| `debate fork <name>` | 세션 분기 복원 |
| `debate forget <name>` | 세션 삭제 |
| `debate export <name> <out.tar.gz>` | 세션 내보내기 |
| `debate log [tail\|path\|clear]` | 로그 보기/관리 |

---

## 6. 실전 예시: 디버깅 토론 흐름

```bash
# 1. 세션 시작 (A=claude, B=cursor, arbiter=claude)
cd ~/my-api-server
debate start

# 2. 양쪽에 가설 부여
debate tell a "서버가 간헐적 500 에러를 반환하는 원인을 분석해. 'DB 커넥션 풀 고갈' 가설을 주장하고 코드에서 증거를 찾아."
debate tell b "동일 에러를 분석해. '동시성 레이스 컨디션' 가설을 주장하고 코드에서 증거를 찾아."

# 3. 3라운드 자동 토론 (반론 모드, 매번 요약해서 깔끔하게)
debate round 3 rebut 20 --sum

# 4. 라운드 모드 바꿔서 추가 (코드 검토)
debate round 2 review 20

# 5. 중재자에게 판정 요청
debate verdict 80
debate hear arbiter 100

# 6. 양쪽에 합의 도출 지시
debate shout "arbiter 의 판정을 보고 최종 결론과 구체적 수정 방안을 정리해."

# 7. 결과 + 로그 확인
debate hear a 100
debate hear b 100
debate log tail 200

# 8. 종료
debate stop
```

---

## 트러블슈팅

### `debate: command not found`
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

### 자동완성이 안 뜸
```bash
fpath=($HOME/.zsh/completions $fpath)
autoload -Uz compinit && compinit
```

### pane 상단 타이틀바가 안 보임
tmux 2.3 이상에서 `pane-border-status` 가 지원됩니다. 버전 확인: `tmux -V`.

### `must read the pane before interacting`
smux 안전장치입니다. CLI 함수는 자동 처리하지만, `tmux-bridge type` 을 직접 쓸 때는 먼저 한번 read 하세요.

### Cursor CLI Agent 가 hang
반드시 tmux pane 안에서 실행해야 합니다. `debate start` 가 자동 처리합니다.

### smux 설치 SSL 에러
```bash
git clone https://github.com/ShawnPana/smux.git ~/.smux-repo
cd ~/.smux-repo && bash install.sh
```

### pane 라벨/타이틀이 잘못된 경우
```bash
tmux-bridge list                    # 현재 pane 목록
tmux-bridge name <pane-id> a        # 라벨 재지정
tmux select-pane -t debate:main.0 -T "A: claude"   # 타이틀 재지정
```

---

## 참고

- [smux (GitHub)](https://github.com/ShawnPana/smux)
- [Cursor CLI](https://cursor.com/cli)
- [Claude Code](https://code.claude.com)
