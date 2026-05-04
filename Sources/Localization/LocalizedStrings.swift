import Foundation

enum Localization {
    static var isEnglish: Bool {
        UserDefaults.standard.string(forKey: "appLanguage") == "English"
    }

    enum Home {
        static var hello: String { isEnglish ? "Hello!" : "안녕하세요!" }
        static var myBingo: String { isEnglish ? "My Bingo" : "내 빙고" }
        static var bingoCount: String { isEnglish ? "boards" : "개" }
        static var emptyTitle: String { isEnglish ? "No bingo yet" : "아직 빙고가 없어요" }
        static var emptySubtitle: String { isEnglish ? "Start with the + button!" : "+ 버튼으로 시작해보세요!" }
        static var createNewBingo: String { isEnglish ? "Create Bingo" : "새 빙고 만들기" }
        static var joinWithCode: String { isEnglish ? "Join with Code" : "초대 코드로 참여" }
        static var inviteCodeCopied: String { isEnglish ? "Invite code copied!" : "초대링크가 복사되었어요" }
        static var viewBingoInfo: String { isEnglish ? "View bingo info" : "빙고 정보 확인" }
        static var copyInviteCode: String { isEnglish ? "Copy invite code" : "초대 코드 복사" }
        static var shareInvite: String { isEnglish ? "Share invite link" : "초대 링크 공유" }
        static var members: String { isEnglish ? "Members" : "멤버" }
        static var boardSize: String { isEnglish ? "Board Size" : "보드 크기" }
        static var leader: String { isEnglish ? "Leader" : "방장" }
        static var member: String { isEnglish ? "Member" : "멤버" }
        static var me: String { isEnglish ? "Me" : "나" }
    }

    enum CreateGroup {
        static var title: String { isEnglish ? "Create Bingo" : "새 빙고 만들기" }
        static var subtitle: String { isEnglish ? "Which bingo\nwill you start?" : "어떤 빙고를\n시작할까요?" }
        static var bingoName: String { isEnglish ? "Bingo Name" : "빙고 이름" }
        static var bingoNamePlaceholder: String { isEnglish ? "e.g.: Our Team 2026 Bucket List" : "예: 우리팀 2026 버킷리스트" }
        static var gridSize: String { isEnglish ? "Grid Size" : "그리드 크기" }
        static var sizeFast: String { isEnglish ? "Fast" : "빠름" }
        static var sizeClassic: String { isEnglish ? "Classic" : "클래식" }
        static var sizeEpic: String { isEnglish ? "Epic" : "에픽" }
        static var inviteCode: String { isEnglish ? "Invite Code" : "초대 코드" }
        static var copy: String { isEnglish ? "Copy" : "복사" }
        static var copied: String { isEnglish ? "Copied" : "복사됨" }
        static var shareCode: String { isEnglish ? "Share this code to invite friends" : "이 코드를 공유하면 친구가 빙고에 참여할 수 있어요." }
        static var create: String { isEnglish ? "Create" : "만들기" }
        static var cancel: String { isEnglish ? "Cancel" : "취소" }
        static var premiumRequired: String { isEnglish ? "Premium Required" : "프리미엄이 필요합니다" }
        static var premiumMessage: String { isEnglish ? "To create more than 2 bingo rooms, you need to purchase premium.\nYou can purchase it in Settings." : "내 빙고 방을 2개 이상 만들기 위해서는 프리미엄 구매가 필요합니다.\n설정창에서 구매하실 수 있습니다." }
        static var buyInSettings: String { isEnglish ? "Buy in Settings" : "설정에서 구매하기" }
    }

    enum Settings {
        static var title: String { isEnglish ? "Settings" : "설정" }
        static var userGuide: String { isEnglish ? "User Guide" : "사용설명서" }
        static var language: String { isEnglish ? "Language" : "언어" }
        static var languageSelect: String { isEnglish ? "Select Language" : "언어 선택" }
        static var appInfo: String { isEnglish ? "App Info" : "앱 정보" }
        static var appStore: String { isEnglish ? "App Store Review" : "앱스토어 평가" }
        static var appVersion: String { isEnglish ? "App Version" : "앱 버전" }
        static var terms: String { isEnglish ? "Terms & Policy" : "이용약관 및 정책" }
        static var termsOfService: String { isEnglish ? "Terms of Service" : "이용약관" }
        static var privacy: String { isEnglish ? "Privacy Policy" : "개인정보 처리방침" }
        static var openSource: String { isEnglish ? "Open Source License" : "오픈소스 라이센스" }
        static var support: String { isEnglish ? "Support" : "고객지원" }
        static var premium: String { isEnglish ? "Premium" : "프리미엄" }
        static var premiumTitle: String { isEnglish ? "BingoRingo Premium" : "BingoRingo 프리미엄" }
        static var premiumDesc: String { isEnglish ? "Unlimited bingo creation, 1,100 won" : "빙고 무제한 생성, 1,100원" }
        static var premiumMember: String { isEnglish ? "✓ Premium Member" : "✓ 프리미엄 회원" }
        static var purchaseDate: String { isEnglish ? "Purchase Date: " : "구매일: " }
        static var close: String { isEnglish ? "Close" : "닫기" }
        // 프리미엄 팝업
        static var benefitTitle: String { isEnglish ? "Premium Benefits" : "프리미엄 혜택" }
        static var benefit1: String { isEnglish ? "Unlimited bingo creation" : "빙고 무제한 생성" }
        static var benefit2: String { isEnglish ? "Access to future paid features" : "차후 업데이트될 유료 항목" }
        static var priceTitle: String { isEnglish ? "Price" : "가격" }
        static var oneTimePurchase: String { isEnglish ? "One-time purchase" : "일회 구매" }
        static var buyNow: String { isEnglish ? "Buy Now" : "구매하기" }
        static var restorePurchase: String { isEnglish ? "Restore Purchases" : "구매 복원" }
        static var cancel: String { isEnglish ? "Cancel" : "취소" }
    }

    enum Board {
        static var complete: String { isEnglish ? "Complete" : "완료" }

        // 보상 섹션
        static var currentGoal: String { isEnglish ? "Current Goal" : "현재 목표" }
        static var editReward: String { isEnglish ? "Edit Reward" : "보상 수정" }
        static var viewReward: String { isEnglish ? "View Reward" : "보상 확인" }
        static var rewardHintLeader: String { isEnglish ? "Set a reward with the Edit button!" : "보상 수정 버튼으로 보상을 설정해보세요!" }
        static var rewardHintMember: String { isEnglish ? "No reward set yet." : "아직 보상이 설정되지 않았어요." }
        static func myProgress(_ done: Int, _ total: Int) -> String { isEnglish ? "My progress \(done)/\(total)" : "내 진행률 \(done)/\(total)칸" }

        // 멤버 섹션
        static var memberStatus: String { isEnglish ? "Members" : "멤버 현황" }
        static func memberN(_ n: Int) -> String { isEnglish ? "Member\(n)" : "멤버\(n)" }
        static func meWithName(_ name: String) -> String { isEnglish ? "Me (\(name))" : "나 (\(name))" }

        // 토스트
        static var bingoReset: String { isEnglish ? "Bingo has been reset." : "빙고가 재설정되었습니다." }
        static var inviteCodeCopied: String { isEnglish ? "Invite code copied!" : "초대 코드가 복사되었습니다." }

        // 빙고 달성 오버레이
        static func bingoAchieved(_ count: Int) -> String { isEnglish ? "\(count) Bingo!" : "\(count)빙고 달성!" }
        static var lineComplete: String { isEnglish ? "A bingo line is complete!" : "빙고 줄이 완성되었어요!" }
        static var confirm: String { isEnglish ? "OK" : "확인" }

        // 전체 완성 오버레이
        static var allBingoComplete: String { isEnglish ? "All Bingo Complete!" : "전체 빙고 완성!" }
        static var allLineComplete: String { isEnglish ? "All bingo lines achieved!" : "모든 빙고 줄을 달성했어요!" }
        static var continueGame: String { isEnglish ? "Continue" : "계속하기" }
        static var quitGame: String { isEnglish ? "Finish" : "그만두기" }

        // 보상 수정 시트
        static var rewardViewTitle: String { isEnglish ? "Rewards for\nbingo!" : "빙고 달성 시\n보상이에요" }
        static var rewardEditTitle: String { isEnglish ? "Set rewards\nfor bingo" : "빙고 달성 시\n보상을 설정하세요" }
        static var allBingoDesc: String { isEnglish ? "Special reward for completing all bingo lines" : "모든 빙고를 완성했을 때 받는 특별 보상이에요" }
        static var save: String { isEnglish ? "Save" : "저장하기" }
        static var cancel: String { isEnglish ? "Cancel" : "취소" }
        static var close: String { isEnglish ? "Close" : "닫기" }
        static func bingoRewardN(_ n: Int) -> String { isEnglish ? "Reward for bingo \(n)" : "\(n)번째 빙고 보상" }
        static var noReward: String { isEnglish ? "No reward" : "보상 없음" }
        static var allBingoRewardPlaceholder: String { isEnglish ? "All-bingo special reward" : "올 빙고 특별 보상" }
        static var allBingo: String { isEnglish ? "All Bingo" : "올 빙고" }
    }

    enum CellDetail {
        static var missionDetail: String { isEnglish ? "Mission Details" : "미션 상세" }
        static var enterMissionDetails: String { isEnglish ? "Enter\nmission details" : "미션을\n입력하세요" }
        static var missionTitle: String { isEnglish ? "Mission Title" : "미션 제목" }
        static var enterMissionName: String { isEnglish ? "Enter mission name" : "미션 이름을 입력하세요" }
        static var details: String { isEnglish ? "Details (Optional)" : "세부사항 (선택)" }
        static var completeButton: String { isEnglish ? "Mission Complete!" : "미션 완료!" }
        static var cancelButton: String { isEnglish ? "Cancel" : "완료 취소하기" }
        static var checkButton: String { isEnglish ? "Mark Complete" : "완료 체크" }
        static var editMission: String { isEnglish ? "Edit Mission" : "미션 수정" }
        static var save: String { isEnglish ? "Save" : "저장하기" }
    }

    enum EditGroup {
        static var title: String { isEnglish ? "Edit Bingo Info" : "빙고 정보 편집" }
        static var editMyBingo: String { isEnglish ? "Edit My Bingo" : "내 빙고 편집" }
        static var bingoName: String { isEnglish ? "Bingo Name" : "빙고 이름" }
        static var bingoNamePlaceholder: String { isEnglish ? "e.g.: Our Team 2026 Bucket List" : "예: 우리팀 2026 버킷리스트" }
        static var onlyLeaderCanEdit: String { isEnglish ? "Only the leader can edit" : "방장만 편집할 수 있어요" }
        static var editComplete: String { isEnglish ? "Edit Complete" : "편집 완료" }
        static var deleteBingo: String { isEnglish ? "Delete Bingo" : "빙고 삭제" }
        static var deleteBingoTitle: String { isEnglish ? "Delete this bingo?" : "빙고를 삭제할까요?" }
        static var deleteButtonText: String { isEnglish ? "Delete" : "삭제" }
        static var deleteMessage: String { isEnglish ? "Deleted bingo cannot be recovered." : "삭제된 빙고는 복구할 수 없어요." }
        static var leaveBingoTitle: String { isEnglish ? "Leave this bingo?" : "빙고에서 나갈까요?" }
        static var leaveButtonText: String { isEnglish ? "Leave" : "나가기" }
        static var leaveBingo: String { isEnglish ? "Leave Bingo" : "빙고 나가기" }
        static var save: String { isEnglish ? "Save" : "저장하기" }
        static var cancel: String { isEnglish ? "Cancel" : "취소" }
    }

    enum Profile {
        static var title: String { isEnglish ? "Profile" : "프로필" }
        static var noNickname: String { isEnglish ? "No nickname" : "닉네임 없음" }
        static var displayName: String { isEnglish ? "Display Name" : "닉네임" }
        static var displayNamePlaceholder: String { isEnglish ? "Enter your display name" : "표시될 이름을 입력하세요" }
        static var profileEmoji: String { isEnglish ? "Profile Emoji" : "프로필 이모지" }
        static var logout: String { isEnglish ? "Logout" : "로그아웃" }
        static var logoutConfirm: String { isEnglish ? "Do you want to logout?" : "로그아웃 하시겠어요?" }
        static var close: String { isEnglish ? "Close" : "닫기" }
        static var save: String { isEnglish ? "Save" : "저장하기" }
        static var cancel: String { isEnglish ? "Cancel" : "취소" }
        static var deleteAccount: String { isEnglish ? "Delete Account" : "계정 삭제" }
        static var deleteAccountConfirm: String { isEnglish ? "Delete your account?" : "계정을 삭제할까요?" }
        static var deleteAccountMessage: String { isEnglish ? "All data will be permanently deleted and cannot be recovered." : "모든 데이터가 영구 삭제되며 복구할 수 없어요." }
    }
}
