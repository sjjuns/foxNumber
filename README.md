# foxNumber 🎱

한국 로또 6/45 번호 생성기 iOS 앱.
다크 럭키(Dark Lucky) 테마의 고급스러운 디자인으로 번호 생성부터 당첨 확인, 통계 분석까지 제공합니다.

## 주요 기능

- **번호 생성** — 1~5게임 랜덤 번호 생성 + 볼 등장 애니메이션
- **번호 저장** — SwiftData 기반 로컬 저장, 회차별 그룹 관리
- **당첨 확인** — 동행복권 API 연동, 일치 번호 하이라이트 + 컨페티 효과
- **통계 분석** — 실제 회차 데이터 기반 핫/콜드 번호, Swift Charts 시각화
- **홈 화면 위젯** — Small / Medium 사이즈 WidgetKit 지원
- **추첨일 알림** — 매주 토요일 오후 8:35 UserNotifications

## 기술 스택

| 항목 | 내용 |
|---|---|
| 플랫폼 | iOS 17+ |
| UI | SwiftUI |
| 데이터 | SwiftData |
| 차트 | Swift Charts |
| 위젯 | WidgetKit |
| 외부 API | 동행복권 (`dhlottery.co.kr`) |
| 프로젝트 관리 | xcodegen |

## 빌드 방법

```bash
# 프로젝트 생성
xcodegen generate

# 시뮬레이터 빌드
xcodebuild -project foxNumber.xcodeproj \
  -scheme foxNumber \
  -destination 'platform=iOS Simulator,id=<UUID>' \
  -configuration Debug build
```

---

## 변경 이력

* 2026-04-28 [jjuns : [커밋해시](https://github.com/sjjuns/foxNumber/commit/커밋해시)]
  * 모던 미니멀 + 다크/라이트 모드 디자인 리뉴얼 — 적응형 ColorSet 9종 추가, accent 색상 체계 전환, 전체 View 레이아웃 개편

* 2026-04-27 [sjjuns : [f0cbe7d](https://github.com/sjjuns/foxNumber/commit/f0cbe7d)]
  * xcodegen 프로젝트 파일 업데이트 (위젯 타겟 및 신규 소스 파일 반영)

* 2026-04-27 [sjjuns : [88def75](https://github.com/sjjuns/foxNumber/commit/88def75)]
  * 프로젝트 초기 구현
    * 번호 생성/저장 (Phase 1): SwiftUI + SwiftData, 볼 애니메이션
    * 당첨 확인 (Phase 2): 동행복권 API 연동, 결과 시트 + 컨페티 효과
    * 통계 (Phase 3): 실제 회차 데이터 병렬 패치, Swift Charts 시각화
    * 홈 화면 위젯 (Phase 3): WidgetKit Small/Medium
    * 앱 아이콘: 다크 럭키 골드 볼 디자인
    * CLAUDE.md 문서화
