# video-to-prompt

영상 파일을 초단위로 프레임 캡처하여 맥락을 분석하고, 영상 생성 AI(Higgsfield / Kling / Runway)용 프롬프트를 역추출하는 **에이전트 스킬**.

Claude Code와 OpenAI Codex CLI 모두에서 동작합니다 (동일한 SKILL.md 표준). API 과금 없이 각 도구의 구독 요금제 안에서 동작합니다 — 에이전트가 세션 안에서 직접 프레임 이미지를 읽어 분석하는 방식이라 별도 API 키가 필요 없습니다.

## 어떻게 동작하나

1. **프레임 추출** — ffmpeg로 1초 단위(1fps) 캡처. 긴 영상은 최대 60프레임으로 자동 샘플링, 768px 리사이즈, 타임스탬프 manifest 생성
2. **시각 분석** — 에이전트가 프레임을 타임스탬프와 함께 읽고 피사체·동작·카메라 워크·샷 사이즈·조명·색감·씬 전환을 분석
3. **프롬프트 생성** — 타겟 모델 문법에 맞춰 Master Prompt + 씬별 프롬프트 생성
   - **Higgsfield**: 카메라 프리셋 매핑 (Dolly, Crash Zoom, Orbit, Tracking 등)
   - **Kling**: 상세 자연어 공식 (Subject + Movement + Scene + Camera + Lighting + Aesthetic)
   - **Runway**: 구조화 단문 (`<camera movement>: <scene>. <details>.`)

## 구조

```
video-to-prompt/
├── SKILL.md                      # 스킬 정의 (분석 워크플로우)
├── scripts/
│   └── extract_frames.sh         # ffmpeg 프레임 추출 스크립트
└── references/
    └── prompt-guides.md          # 모델별 프롬프트 문법 가이드
```

## 설치

### 0. 의존성

```bash
brew install ffmpeg
```

### 1. 저장소 클론

```bash
git clone <this-repo-url> ~/git/VIDEOTOPROMPT
```

### 2-A. Claude Code에 설치

```bash
mkdir -p ~/.claude/skills
ln -sfn ~/git/VIDEOTOPROMPT/video-to-prompt ~/.claude/skills/video-to-prompt
```

새 세션부터 자동 인식됩니다. 호출: `/video-to-prompt <영상 경로>` 또는 자연어("이 영상 분석해서 프롬프트 만들어줘").

### 2-B. Codex CLI에 설치

```bash
mkdir -p ~/.codex/skills
ln -sfn ~/git/VIDEOTOPROMPT/video-to-prompt ~/.codex/skills/video-to-prompt
```

Codex 재시작 후 인식됩니다. 호출: `$video-to-prompt <영상 경로>` 또는 `/skills`에서 선택.

> 심링크 방식이므로 저장소에서 `git pull` 하면 양쪽 도구에 동시 반영됩니다. 심링크 대신 디렉토리를 통째로 복사해도 됩니다.

### 프로젝트 단위 설치 (선택)

특정 프로젝트에서만 쓰려면 전역 대신:
- Claude Code: `<project>/.claude/skills/video-to-prompt/`
- Codex: `<project>/.agents/skills/video-to-prompt/`

## 사용 예시

```
/video-to-prompt ~/Videos/sample.mp4
```

```
이 영상 분석해서 Kling 프롬프트 만들어줘: ~/Videos/sample.mp4
```

타겟 모델을 지정하지 않으면 Higgsfield / Kling / Runway 3종을 모두 생성합니다.

출력물:
1. **영상 분석 요약** — 씬별 타임스탬프 / 내용 / 카메라 / 조명 표
2. **Master Prompt** — 영상 전체를 재현하는 단일 프롬프트 (모델별, 영어)
3. **Scene-by-scene Prompts** — 컷이 여러 개면 씬별 분리 프롬프트
4. **메타** — 종횡비, 원본 길이, 추천 생성 설정

## 프레임 추출 스크립트 단독 사용

```bash
bash video-to-prompt/scripts/extract_frames.sh <video> <output_dir> [max_frames] [start_sec] [duration_sec]
```

- `max_frames` (기본 60) — 초과하는 긴 영상은 샘플링 간격이 자동으로 넓어짐
- `start_sec` / `duration_sec` — 특정 구간만 촘촘히 재추출할 때 (씬 정밀 분석용)
- 출력: `frame_%04d.jpg` + 타임스탬프 매핑이 담긴 `manifest.txt`

## 알아두기

- 프레임 분석은 각 도구의 **구독 사용량**을 소모합니다 (긴 영상일수록 많이). 60프레임 기본값은 이 균형을 위한 것입니다.
- 화면만 분석하므로 **대사/내레이션(오디오)은 반영되지 않습니다**. Whisper 로컬 전사 연동이 다음 개선 후보입니다.
- 프레임에서 실제 관찰된 것만 프롬프트에 반영하며, 브랜드명·실존 인물명은 일반화합니다.
