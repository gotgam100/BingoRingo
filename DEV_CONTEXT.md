# BingoRingo 개발 컨텍스트 (2026-05-05 기준)

## 프로젝트 개요
- **앱명:** BingoRingo (빙고링고)
- **플랫폼:** iOS (SwiftUI)
- **백엔드:** Firebase Firestore + Firebase Storage
- **인증:** Google Sign-In
- **결제:** StoreKit 2 (프리미엄)
- **현재 버전:** 1.1.2 (인증 사진 기능 포함)
- **Xcode 프로젝트 경로:** `/Users/baekmac/맥북_Home/01_개인작업/05_CODE/Bingo/BingoRingo`

---

## 앱 구조 요약

### 핵심 기능
- 그룹 빙고방 생성/참여 (초대 코드)
- 멤버별 미션 셀 완료 체크
- 빙고 라인 감지 및 축하 애니메이션
- 미션 인증 사진 업로드 (Firebase Storage)
- 보상 설정 (빙고 줄별, 전체 완성)
- 초대 공유 (iOS 공유 시트)
- 한국어/영어 지원 (`Localization.isEnglish`)

### 디자인 시스템
- `BRColors` — 커스텀 컬러 팔레트
- `Paperlogy` — 커스텀 폰트
- `BRColors.primaryGradient`, `BRColors.cyanGradient` 등

---

## 주요 파일 구조

```
Sources/
├── Models/
│   ├── BingoCell.swift        ← 인증사진 포함, 완전 방어 디코딩
│   ├── BingoBoard.swift       ← 안전한 cell(row:col:), 방어 디코딩
│   ├── BingoGroup.swift       ← boardSize 등 신규필드 방어 디코딩
│   ├── BingoReward.swift
│   └── Member.swift           ← @DocumentID, profileEmoji 방어 디코딩
├── ViewModels/
│   ├── BoardViewModel.swift   ← toggleCell, uploadProofImage, deleteProofImage
│   ├── GroupViewModel.swift
│   └── AuthViewModel.swift
├── Services/
│   ├── FirestoreService.swift
│   ├── StorageService.swift   ← 신규: 인증사진 업로드/삭제/압축
│   └── PremiumManager.swift
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift     ← 초대 공유 시트, 버전 자동반영
│   │   └── EditGroupSheet.swift ← 삭제/나가기 에러 처리 개선
│   ├── Board/
│   │   ├── BoardView.swift
│   │   └── BingoCellView.swift
│   └── Cell/
│       └── CellDetailView.swift ← 인증사진 UI, @ObservedObject 사용
└── Localization/
    └── LocalizedStrings.swift
```

---

## 모델 상세

### BingoCell
```swift
struct BingoCell: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var description: String = ""
    var completedBy: [String] = []
    var completedAt: [String: Date] = [:]
    var proofImageURLs: [String: String] = [:]  // ← 신규 (인증사진 URL)
}
```
- `init(from:)` 커스텀 — `try? decode()` 패턴으로 어떤 실패도 기본값 처리
- `init(title:description:)` 커스텀 init 포함

### BingoBoard
```swift
struct BingoBoard: Identifiable, Codable {
    var id, title: String
    var size: Int = 5
    var cells: [BingoCell]
    var memberIDs: [String]
    var leaderID: String
    var createdAt: Date = Date()
}
```
- `cell(row:col:)` — 인덱스 범위 초과 시 빈 셀 반환 (크래시 방지)
- `setCell(_:row:col:)` — 인덱스 범위 초과 시 무시
- cells 디코딩 실패 시 → size×size 빈 셀로 자동 복구

### BingoGroup
```swift
struct BingoGroup: Identifiable, Codable, Hashable {
    var id, name, inviteCode: String
    var memberIDs, lineRewards: [String]
    var leaderID: String
    var boardID: String?
    var boardSize: Int = 5
    var completedLinesCount: Int = 0
    var allBingoReward: String = ""
    var isCompleted: Bool = false
    var createdAt: Date = Date()
}
```

### Member
```swift
struct Member: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var displayName: String
    var profileImageURL: String?
    var email: String
    var profileEmoji: String = "😀"
}
```
- `CodingKeys`에 `id` 제외 (`@DocumentID`는 Firebase SDK가 처리)

---

## Firestore 디코딩 핵심 원칙

> **모든 모델의 `init(from decoder:)`는 `try? decode()` 패턴 사용**

```swift
// ❌ 잘못된 방법 (키 없으면 에러, 타입 불일치도 에러)
someField = try c.decodeIfPresent(String.self, forKey: .someField) ?? ""

// ✅ 올바른 방법 (키 없음 + 타입 불일치 모두 기본값)
someField = (try? c.decode(String.self, forKey: .someField)) ?? ""
```

이유: `decodeIfPresent`는 키가 없을 때만 nil 반환, 타입 불일치 시엔 여전히 throw.
`try? decode()`는 어떤 실패도 nil로 처리 → 기본값 사용.

앱 업데이트로 새 필드 추가 시, 기존 Firestore 데이터가 로딩 실패하거나 크래시하는 것을 방지.

---

## BoardViewModel 주요 기능

```swift
// 셀 완료/취소 (취소 시 인증사진 자동 삭제)
func toggleCell(row: Int, col: Int, memberID: String) async

// 인증사진 업로드
func uploadProofImage(row: Int, col: Int, memberID: String, image: UIImage) async throws

// 인증사진 삭제
func deleteProofImage(row: Int, col: Int, memberID: String) async
```

- `@MainActor` 클래스
- `previousAllCellsComplete: Bool` 로 전체 완성 조건 추적
- 전체 완성 = `board.cells.allSatisfy { $0.isCompleted(for: memberIDs) }`
- 빙고 줄 달성과 전체 완성은 별개로 처리

---

## StorageService

```swift
// 경로: proof/{groupID}/{cellID}/{memberID}
func uploadProofImage(_ image: UIImage, groupID: String, cellID: String, memberID: String) async throws -> String
func deleteProofImage(groupID: String, cellID: String, memberID: String) async
```

- 이미지 압축: 최대 1024px, JPEG 60%
- Firebase Storage Blaze 플랜 (무료 티어: 5GB 저장, 1GB/일 다운로드)
- **주의:** Xcode 프로젝트에 수동으로 타겟 추가 필요 (파일 탐색기 → 우클릭 → Add Files)

---

## Firebase Storage 규칙

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /proof/{groupID}/{cellID}/{memberID} {
      allow read: if request.auth != null;
      allow write, delete: if request.auth != null && request.auth.uid == memberID;
    }
  }
}
```

---

## CellDetailView 주요 특징

- `@ObservedObject private var boardVM: BoardViewModel` ← 외부 소유 객체이므로 반드시 ObservedObject
- `currentCell` — 항상 `boardVM.board?.cell(row:col:)` 기반 실시간 데이터
- `isCompletedByMe`, `completedCount`, `myProofURL` 모두 `currentCell` 기반
- 인증사진: 썸네일 탭 → 전체화면, 길게 누르면 삭제 contextMenu
- 완료 시에만 사진 업로드 가능, 완료 취소 시 자동 삭제

---

## BingoCellView 상태별 디자인

| 상태 | 배경색 | 체크마크 |
|------|--------|---------|
| 전원 완료 | primaryColor (라인색) | 빨간 체크 (우상단) |
| 친구 완료, 내가 미완료 | primaryMid (진함) | 반투명 ghost 체크 |
| 내가 완료, 친구 미완료 | primaryDim (연함) | 매우 연한 체크 (opacity 0.35) |
| 미완료 | #FFF8F0 | 없음 |

---

## 알려진 이슈 및 해결 이력

### 해결됨
1. **전체 빙고 완성 조건 오류** — 빙고 3줄 = 전체 완성으로 잘못 처리 → `allCellsComplete` 조건으로 수정
2. **기존 빙고방 로딩 실패** — Firestore 신규 필드 없을 때 디코딩 실패 → `try? decode()` 패턴으로 해결
3. **삭제한 방 재등장** — 오래된 방이 디코딩 실패로 숨겨져 있다가 수정 후 재노출 → 직접 재삭제 필요
4. **미션 완료 시 앱 크래시** — `cells = []`일 때 배열 직접 접근 → `cell(row:col:)` 범위 체크 추가
5. **CellDetailView @StateObject 충돌** — BoardView와 CellDetailView 모두 @StateObject로 동일 객체 소유 → `@ObservedObject`로 수정
6. **삭제/나가기 실패 무시** — `try?`로 에러 묵살 → `try` + 에러 메시지 표시로 개선

### 앞으로 새 필드 추가 시 체크리스트
- [ ] 모델에 프로퍼티 추가 (기본값 포함)
- [ ] `init(from:)`에 `(try? c.decode(...)) ?? 기본값` 으로 추가
- [ ] `CodingKeys`에 케이스 추가
- [ ] `encode(to:)`는 합성(synthesis) 사용 — 별도 구현 불필요

---

## 앱 설정 / 버전

- `Info.plist`, `Resources/Info.plist` 두 곳 모두 수정
- `project.pbxproj`의 `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`도 일치시킬 것
- 앱 내 버전 표시: `Bundle.main.infoDictionary?["CFBundleShortVersionString"]` 자동 반영

---

## 초대 공유 기능

HomeView contextMenu → "초대 공유하기" → iOS 공유 시트
```swift
// 한국어 메시지 예시
"빙고링고 같이 해요! 🎯\n\n초대 코드: \(group.inviteCode)\n..."
```
- `ShareSheet`: `UIViewControllerRepresentable` (HomeView 하단에 정의)
- `@State private var shareGroup: BingoGroup?` 로 관리

---

## 로컬라이제이션 패턴

```swift
// 모든 텍스트 분기
Localization.isEnglish ? "English text" : "한국어 텍스트"

// LocalizedStrings.swift에 정적 프로퍼티로 정의
static var shareInvite: String { isEnglish ? "Share invite" : "초대 공유하기" }
```

---

## 최근 완료 작업 (2026-05-05)

### 인증 사진 기능
- `CellDetailView`: 사진 업로드 → 미션 자동 완료, 삭제 → 자동 취소
- 완료 토스트 ("미션 완료" 녹색 BRColors.primary), 취소 토스트 ("완료 취소" 빨간색 BRColors.tertiary)
- TabView 슬라이드 + 탭 가능한 화살표 + 페이지 번호 항상 표시 (1/1 포함)
- 수정 버튼(연필 아이콘) → 바로 사진 라이브러리 열림 (소스 선택 단계 생략)
- `Sources/Services/ImageCache.swift` 신규 파일 분리 (메모리 NSCache + 디스크 캐시)
- `BoardView`: `.onChange(of: boardVM.board)` 에서 모든 인증사진 URL 프리패치
- 이미지 압축: 600px / JPEG 45%로 축소

### 빙고 방 인원 제한
- `GroupViewModel.joinGroup()`: 10명 초과 시 `GroupError.full` throw
- 오류 메시지 한/영 분기: "방이 꽉 찼어요. (최대 10명)" / "This room is full (max 10 members)."
- `BingoBoard`, `BingoCell` Equatable 채택 (onChange 컴파일 요구사항)

### 권한 및 설정
- `Resources/Info.plist`에 `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` 추가

### 법적 문서 업데이트 (시행일 2026-05-05)
- `docs/privacy.html`: 인증사진 수집 항목, Firebase Storage 위탁, 보유기간 추가 (한/영)
- `docs/terms.html`: 콘텐츠 정의에 인증사진 추가, 금지 콘텐츠에 부적절 사진 항목 추가 (한/영)

### 사용설명서
- `UserGuideView` 빙고 화면 섹션: 인증사진으로 자동 완료 안내로 교체

---

## 다음 할 일
- [ ] Xcode 빌드 & 실기기 테스트 (인증사진, 완료, 빙고 감지)
- [ ] App Store Connect 심사 제출
