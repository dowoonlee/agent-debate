# Homebrew Tap 배포 가이드

`debate` CLI 를 `brew tap` 으로 배포하기 위한 단계.

## 사전 준비

1. **이 저장소(`agent-debate`)를 public 으로 전환** (또는 private 유지 시 SSH 인증으로만 설치 가능)
2. v0.1.0 태그가 푸시되어 있어야 함 — ✅ 완료 (`033443e`)

## 1. tap 저장소 생성

GitHub 에서 새 저장소 생성:

- **이름**: `homebrew-debate` (반드시 `homebrew-` 접두어)
- **소유자**: `dowoonlee`
- public

```bash
gh repo create dowoonlee/homebrew-debate --public --description "Homebrew tap for debate CLI"
# 또는 GitHub 웹에서 수동 생성
```

## 2. tap 저장소에 Formula 배치

```bash
git clone git@github.com:dowoonlee/homebrew-debate.git
cd homebrew-debate
mkdir -p Formula
cp /Users/a11706/.dev/agent-debate/Formula/debate.rb Formula/
git add Formula/debate.rb
git commit -m "Add debate v0.1.0 formula"
git push
```

## 3. 사용자 설치 흐름

```bash
brew tap dowoonlee/debate
brew install debate
debate doctor
```

또는 한 줄:

```bash
brew install dowoonlee/debate/debate
```

## 4. Formula 검증 (배포 전 로컬 테스트)

```bash
brew install --build-from-source ./Formula/debate.rb
brew test debate
brew audit --new-formula --strict ./Formula/debate.rb
```

## 5. 새 버전 릴리스 흐름

코드 수정 후:

```bash
# 본 저장소(agent-debate)에서
git tag v0.2.0
git push origin v0.2.0
COMMIT=$(git rev-parse v0.2.0)
echo "revision: $COMMIT"

# Formula/debate.rb 의 tag, revision, version 업데이트
# tap 저장소에서:
cd ~/path/to/homebrew-debate
# Formula/debate.rb 수정
git commit -am "Update debate to v0.2.0"
git push
```

## 6. (선택) tarball 기반 배포로 전환

현재 Formula 는 git URL + tag + revision 방식 (sha256 불필요, private 저장소도 가능). 표준 brew 관행은 tarball + sha256 입니다. 저장소가 public 이라면:

```bash
curl -fsSL https://github.com/dowoonlee/agent-debate/archive/refs/tags/v0.1.0.tar.gz -o /tmp/v0.1.0.tar.gz
shasum -a 256 /tmp/v0.1.0.tar.gz
```

그리고 Formula 의 `url` 블록을 다음으로 교체:

```ruby
url "https://github.com/dowoonlee/agent-debate/archive/refs/tags/v0.1.0.tar.gz"
sha256 "<위에서 구한 sha256>"
```

장점: brew 가 캐싱 잘 되고, git clone 비용 없음.
단점: 매 릴리스마다 sha256 갱신 필요.

## 참고

- [Homebrew Formula Cookbook](https://docs.brew.sh/Formula-Cookbook)
- [How to Create and Maintain a Tap](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)
