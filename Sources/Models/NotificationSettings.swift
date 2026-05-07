import Foundation

/// 빙고방별 알림 설정 (방 × 멤버 단위로 저장)
/// Firestore 경로: groups/{groupID}/memberSettings/{memberID}
struct NotificationSettings: Codable, Equatable {
    var notifMissionComplete: Bool = true   // 멤버가 미션 완료
    var notifBingoAchieved: Bool = true     // 빙고 달성 / 올 빙고
    var notifReactionComment: Bool = true   // 내 사진에 반응/댓글
    var notifNewMember: Bool = true         // 새 멤버 참여

    init(notifMissionComplete: Bool = true,
         notifBingoAchieved: Bool = true,
         notifReactionComment: Bool = true,
         notifNewMember: Bool = true) {
        self.notifMissionComplete = notifMissionComplete
        self.notifBingoAchieved = notifBingoAchieved
        self.notifReactionComment = notifReactionComment
        self.notifNewMember = notifNewMember
    }

    // MARK: - Firestore 역호환: 누락된 키는 모두 true로 기본값 처리

    enum CodingKeys: String, CodingKey {
        case notifMissionComplete, notifBingoAchieved, notifReactionComment, notifNewMember
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        notifMissionComplete = (try? c.decode(Bool.self, forKey: .notifMissionComplete)) ?? true
        notifBingoAchieved   = (try? c.decode(Bool.self, forKey: .notifBingoAchieved))   ?? true
        notifReactionComment = (try? c.decode(Bool.self, forKey: .notifReactionComment)) ?? true
        notifNewMember       = (try? c.decode(Bool.self, forKey: .notifNewMember))       ?? true
    }
}
