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
