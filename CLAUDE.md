# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

한국 로또 6/45 번호 생성기 iOS 앱. 다크 럭키(Dark Lucky) 테마 디자인.
- **최소 지원**: iOS 17+
- **언어**: Swift 5.9 / SwiftUI
- **데이터**: SwiftData
- **외부 API**: 동행복권 (`https://www.dhlottery.co.kr/common.do?method=getLottoNumber&drwNo={회차}`)

---

## 커밋 규칙

Conventional Commits 형식을 따른다.

```
<타입>: <제목>
```

| 타입 | 용도 |
|---|---|
| `feat` | 새 기능 추가 |
| `fix` | 버그 수정 |
| `chore` | 빌드/설정/의존성 변경 |
| `docs` | 문서만 변경 (README, CLAUDE.md 등) |
| `style` | 코드 포맷/UI 스타일 (기능 변화 없음) |
| `refactor` | 기능 변화 없는 코드 구조 개선 |
| `test` | 테스트 추가/수정 |

- 제목은 한국어, 명령형으로 작성 (`추가`, `수정`, `제거`)
- `docs: README 업데이트` 자동 커밋은 훅이 생성하므로 수동 작성 불필요

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
