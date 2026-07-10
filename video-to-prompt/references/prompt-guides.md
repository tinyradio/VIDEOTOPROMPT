# Target-Model Prompt Guides

영상 분석 결과를 각 생성 모델의 문법으로 변환할 때 사용하는 가이드.
프롬프트는 항상 **영어**로 작성한다 (영상 생성 모델은 영어 프롬프트 성능이 가장 좋음).

## 공통 원칙

- 프레임에서 관찰한 사실만 묘사한다. 추측한 내용은 넣지 않는다.
- 부정문 금지 ("no camera shake" ❌ → "stable locked-off shot" ✅)
- 현재형, 시각적 언어로. 스토리 배경 설명이 아니라 화면에 보이는 것을 쓴다.
- 포함할 요소: 피사체(외형 디테일) / 동작 / 배경·환경 / 카메라 움직임 / 샷 사이즈 / 조명 / 색감·그레이딩 / 무드 / 스타일(실사, 애니메이션, 필름 그레인 등)
- 원본 영상의 종횡비와 길이를 프롬프트 메타로 함께 알려준다.

## Higgsfield

카메라 모션 **프리셋 중심** 모델. 분석에서 감지한 카메라 움직임을 아래 프리셋 중 가장 가까운 것으로 매핑해서 명시한다.

주요 프리셋: Dolly In / Dolly Out, Crash Zoom In / Crash Zoom Out, Orbit (Arc Left/Right),
Whip Pan, Crane Up / Crane Down, FPV Drone, Bullet Time, Snorricam, Handheld,
Static / Locked-off, Zoom In / Zoom Out, 360 Orbit, Super Dolly, Robo Arm

형식:
```
Camera preset: <closest preset>
Prompt: <subject with details> <action>, <environment>, <lighting>, <color/mood>, <style>
```

- 카메라 움직임이 프롬프트 품질의 핵심. 프레임 간 구도 변화를 근거로 프리셋을 고른다.
- 동작 강도(subtle/strong)도 언급하면 좋다.

## Kling

자연어 상세 묘사에 강한 모델. 공식 권장 공식:

```
Subject (detailed) + Movement + Scene/Environment + Camera language + Lighting + Aesthetic
```

- 카메라는 문장으로 서술: "the camera slowly pushes in", "handheld tracking shot following the subject"
- 시네마틱 수식어에 잘 반응: "shallow depth of field", "35mm film look", "volumetric light"
- 한 프롬프트에 하나의 연속된 장면만. 컷이 바뀌는 영상은 씬별로 프롬프트를 분리한다.

## Runway (Gen-3 / Gen-4)

간결하고 구조화된 형식을 선호. 권장 구조:

```
<camera movement>: <establishing scene>. <additional details>.
```

예: `Slow dolly in: a woman in a red coat stands on a foggy pier at dawn. Soft diffused light, muted teal color grade, cinematic 35mm.`

- 짧고 밀도 있게 (긴 산문보다 구조화된 한 단락)
- 장면 "변화"보다 "움직임"을 묘사 (image-to-video 특성)
- 스타일 키워드를 끝에 배치: film grain, anamorphic, documentary style 등

## 출력 형식 (스킬 최종 결과물)

1. **영상 분석 요약** — 씬 구분, 씬별 타임스탬프·내용·카메라·조명 표
2. **Master Prompt** — 영상 전체(또는 대표 씬)를 재현하는 단일 프롬프트, 타겟 모델별로
3. **Scene-by-scene Prompts** — 컷이 여러 개면 씬별 프롬프트 목록
4. 메타 정보 — 종횡비, 길이, 추천 생성 길이
