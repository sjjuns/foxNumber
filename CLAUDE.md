# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Claude 행동 지침

일반적인 LLM 코딩 실수를 줄이기 위한 행동 가이드라인. 프로젝트별 지침과 함께 적용할 것.

**트레이드오프:** 이 지침은 속도보다 신중함을 우선시한다. 단순한 작업은 판단에 따라 적절히 적용할 것.

### 1. 코딩 전 생각하기

**가정하지 말 것. 혼란을 숨기지 말 것. 트레이드오프를 드러낼 것.**

구현 전에:
- 가정을 명시적으로 서술할 것. 불확실하면 물어볼 것.
- 여러 해석이 가능하면 모두 제시할 것 — 조용히 하나만 선택하지 말 것.
- 더 단순한 접근법이 있으면 말할 것. 필요 시 반론을 제기할 것.
- 불명확한 게 있으면 멈출 것. 무엇이 혼란스러운지 명시하고 물어볼 것.

### 2. 단순함 우선

**문제를 해결하는 최소한의 코드. 추측성 코드 금지.**

- 요청받은 것 이상의 기능 추가 금지.
- 단일 사용 코드에 추상화 금지.
- 요청하지 않은 "유연성"이나 "설정 가능성" 추가 금지.
- 불가능한 시나리오에 대한 에러 처리 금지.
- 200줄로 쓴 코드가 50줄로 가능하다면 다시 작성할 것.

자문할 것: "시니어 엔지니어가 이걸 보면 과도하게 복잡하다고 할까?" 그렇다면 단순화할 것.

### 3. 외과적 변경

**꼭 필요한 것만 건드릴 것. 자신이 만든 문제만 정리할 것.**

기존 코드 편집 시:
- 인접한 코드, 주석, 포맷을 "개선"하지 말 것.
- 망가지지 않은 것을 리팩토링하지 말 것.
- 자신의 방식과 달라도 기존 스타일을 맞출 것.
- 관련 없는 데드 코드를 발견하면 언급만 할 것 — 삭제하지 말 것.

자신의 변경으로 고아가 된 것들:
- 자신의 변경으로 인해 사용되지 않게 된 import/변수/함수는 제거할 것.
- 미리 존재하던 데드 코드는 요청받지 않는 한 제거하지 말 것.

기준: 변경된 모든 줄이 사용자의 요청과 직접 연결되어야 한다.

### 4. 목표 중심 실행

**성공 기준을 정의할 것. 검증될 때까지 반복할 것.**

작업을 검증 가능한 목표로 변환:
- "유효성 검사 추가" → "잘못된 입력에 대한 테스트를 작성한 후 통과시킬 것"
- "버그 수정" → "버그를 재현하는 테스트를 작성한 후 통과시킬 것"
- "X 리팩토링" → "리팩토링 전후로 테스트가 통과하는지 확인할 것"

여러 단계 작업의 경우 간략한 계획을 먼저 제시:
```
1. [단계] → 검증: [확인 항목]
2. [단계] → 검증: [확인 항목]
3. [단계] → 검증: [확인 항목]
```

명확한 성공 기준이 있으면 독립적으로 반복 진행 가능. 약한 기준("동작하게 만들기")은 지속적인 확인이 필요.

> **이 지침이 잘 적용되고 있다면:** diff에서 불필요한 변경이 줄어들고, 과도한 복잡성으로 인한 재작성이 줄어들며, 실수 후가 아닌 구현 전에 명확화 질문이 나온다.

---

## 프로젝트 개요

한국 로또 6/45 번호 생성기 iOS 앱. 다크 럭키(Dark Lucky) 테마 디자인.
- **최소 지원**: iOS 17+
- **언어**: Swift 5.9 / SwiftUI
- **데이터**: SwiftData
- **외부 API**: 동행복권 (`https://www.dhlottery.co.kr/common.do?method=getLottoNumber&drwNo={회차}`)

---

## Git 커밋 규칙

> ⚠️ **git commit 전에 반드시 아래 절차를 따를 것**
> 사용자가 명시적으로 승인하기 전까지 커밋 금지

### 커밋 전 변경 요약 (필수)

커밋 전에 **텍스트로 변경 내용을 간략히 요약**하여 사용자에게 보여줄 것.
요약 확인 및 승인 후에만 `git commit` 실행.

요약에 포함할 내용 (텍스트, 마크다운):
```
1. 구현 요약       무엇을 만들었는지 한국어로 1~3줄
2. 변경 파일 목록  파일명 / 상태(추가·수정·삭제) / +줄 -줄 수
3. 빌드 결과       BUILD SUCCEEDED / FAILED
4. 커밋 메시지 초안
```

요약을 보여준 뒤 **"HTML 보고서도 만들까요?"** 라고 물어볼 것.
사용자가 원할 때만 `commit_report.html`을 생성하고 Claude Preview로 렌더링.

### README.md 업데이트 (필수)

커밋 전에 `README.md` 변경 이력 섹션에 항목을 **맨 위에** 추가할 것.

형식:
```
* YYYY-MM-DD [GitHub ID : [커밋해시](https://github.com/sjjuns/foxMoney/commit/커밋해시)]
  * 변경 내용 한 줄 요약
```

예시:
```
* 2026-04-24 [sjjuns : [3dc7368](https://github.com/sjjuns/foxMoney/commit/3dc7368)]
  * Phase 2 거래 입력/편집 시트 구현 — 커스텀 키패드, 카테고리/결제수단 선택
```

**기능 단위로 커밋** — Phase 완료가 아닌 기능 하나 완성될 때마다 커밋

### 커밋 메시지 형식
```
타입: 간단한 설명 (한국어 가능)

타입:
  feat     새 기능
  fix      버그 수정
  refactor 리팩토링 (기능 변화 없음)
  style    UI/레이아웃 변경
  model    데이터 모델 변경
  config   설정 파일 변경
  docs     문서 변경 (PLAN.md 등)
```

### 커밋 예시
```
feat: WriteView 날짜바 컴포넌트 구현
model: Transaction에 createdAt 필드 추가
style: 지출 리스트 행 2줄 레이아웃 적용
feat: 거래 추가 입력 시트 구현
```

### git push 규칙
- `git push`도 커밋과 동일하게 **사용자 확인 후 실행**
- force push 절대 금지 (settings.json에서 차단됨)
- 기본 브랜치: `main`

---

## 빌드 명령어

> `.xcodeproj`는 `xcodegen`으로 생성된다. `project.yml`을 수정한 후 반드시 재생성할 것.

```bash
# 프로젝트 재생성 (project.yml 수정 시 필수)
xcodegen generate

# 앱 빌드
xcodebuild -project foxNumber.xcodeproj \
  -scheme foxNumber \
  -destination 'platform=iOS Simulator,id=<시뮬레이터 UUID>' \
  -configuration Debug build

# 위젯 빌드
xcodebuild -project foxNumber.xcodeproj \
  -scheme foxNumberWidget \
  -destination 'platform=iOS Simulator,id=<시뮬레이터 UUID>' \
  -configuration Debug build

# 사용 가능한 시뮬레이터 UUID 확인
xcrun simctl list devices available | grep iPhone
```

> 현재 개발 환경에서 검증된 시뮬레이터: `iPhone 16 Pro (E95A570F-C392-41AE-8CD2-C030938DF68E)`

---

## 아키텍처

### 레이어 구조

```
Views  →  ViewModels  →  Services  →  외부 API
  ↓                          ↓
Components              SwiftData (LottoNumber)
  ↓
DesignSystem
```

- **Views**: SwiftUI 화면. ViewModel을 `@State`로 소유 (`@Observable` 패턴).
- **ViewModels**: `@Observable` 매크로 사용. `@MainActor`로 UI 업데이트 보장.
- **Services**: `LottoService.shared` 싱글톤 — 번호 생성, API 호출, 회차 계산 담당.
- **Cache**: `WinningNumberCache.shared` — API 응답을 메모리에 캐시, 중복 요청 방지.

### 탭 구성

| 탭 | View | ViewModel |
|---|---|---|
| 생성 | `GenerateView` | `GenerateViewModel` |
| 내 번호 | `MyNumbersView` | `CheckViewModel` |
| 통계 | `StatsView` | `StatsViewModel` |
| 설정 | `SettingsView` | — |

### 당첨 확인 흐름

`MyNumbersView` → `CheckViewModel.check(item:)` → `LottoService.fetchWinningNumber(round:)` → `WinningNumberCache` → `WinningResultView` (sheet)

통계 API 호출은 5개씩 청크로 병렬 패치 (`TaskGroup`) 후 결과를 집계한다.

---

## 핵심 모델

**`LottoNumber`** (SwiftData `@Model`): 사용자가 저장한 번호. `checkResult: CheckResult?`가 nil이면 미확인 상태.

**`WinningNumber`**: API 응답 구조체. `Codable & Equatable`.

**`CheckResult`**: `Codable`. SwiftData에 직렬화되어 `LottoNumber`에 저장됨.

**`LottoRank`**: `.none`(낙첨) ~ `.first`(1등). `rawValue`는 Int (0=낙첨, 1~5=등수).

---

## 디자인 시스템

`DesignSystem.swift`의 정적 상수만 사용할 것. 하드코딩된 색상값 사용 금지.

- 볼 색상: `DesignSystem.ballColor(for: number)` — 번호 구간별 실제 로또 색상 반환 (1-10 노랑, 11-20 파랑, 21-30 빨강, 31-40 회색, 41-45 초록)
- `LottoBallView(number:size:isHighlighted:)` — 앱 전체에서 번호 볼 표시에 사용
- `WidgetBall` — 위젯 전용 경량 볼 (DesignSystem 의존성 없이 인라인 색상)

---

## 위젯

`Sources/foxNumberWidget/foxNumberWidget.swift` 단일 파일로 구성. 앱 코드를 import할 수 없으므로 `LottoService`의 회차 계산 로직과 볼 색상이 인라인으로 중복 정의되어 있다. 로직 변경 시 위젯 파일도 함께 수정해야 한다.

---

## 앱 아이콘

아이콘은 Python PIL로 프로그래밍 방식으로 생성됨 (`AppIcon-1024.png` 등). 디자인을 변경하려면 Python 스크립트를 다시 실행해 PNG를 재생성하고 `Assets.xcassets/AppIcon.appiconset/`에 덮어쓴 뒤 xcodegen을 재실행한다.
