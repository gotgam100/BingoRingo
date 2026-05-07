import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    // MARK: - Group

    func createGroup(_ group: BingoGroup) async throws {
        try db.collection("groups").document(group.id).setData(from: group)
    }

    func fetchGroup(by id: String) async throws -> BingoGroup {
        try await db.collection("groups").document(id).getDocument(as: BingoGroup.self)
    }

    func fetchGroup(byInviteCode code: String) async throws -> BingoGroup? {
        let snapshot = try await db.collection("groups")
            .whereField("inviteCode", isEqualTo: code)
            .limit(to: 1)
            .getDocuments()
        return try snapshot.documents.first?.data(as: BingoGroup.self)
    }

    func listenToGroup(id: String, onChange: @escaping (BingoGroup) -> Void) -> ListenerRegistration {
        db.collection("groups").document(id).addSnapshotListener { snapshot, _ in
            guard let group = try? snapshot?.data(as: BingoGroup.self) else { return }
            onChange(group)
        }
    }

    // MARK: - Board

    func createBoard(_ board: BingoBoard) async throws {
        try db.collection("boards").document(board.id).setData(from: board)
    }

    func updateBoard(_ board: BingoBoard) async throws {
        try db.collection("boards").document(board.id).setData(from: board, merge: true)
    }

    func removeInteractions(boardID: String, interactionKey: String) async throws {
        try await db.collection("boards").document(boardID).updateData([
            "cellReactions.\(interactionKey)": FieldValue.delete(),
            "cellComments.\(interactionKey)": FieldValue.delete()
        ])
    }

    func listenToBoard(id: String, onChange: @escaping (BingoBoard) -> Void) -> ListenerRegistration {
        db.collection("boards").document(id).addSnapshotListener { snapshot, _ in
            guard let board = try? snapshot?.data(as: BingoBoard.self) else { return }
            onChange(board)
        }
    }

    func updateGroupLines(groupID: String, count: Int) async throws {
        try await db.collection("groups").document(groupID).updateData([
            "completedLinesCount": count
        ])
    }

    func updateGroupBoardID(groupID: String, boardID: String) async throws {
        try await db.collection("groups").document(groupID).updateData([
            "boardID": boardID
        ])
    }

    func updateBoardMemberIDs(boardID: String, memberIDs: [String]) async throws {
        try await db.collection("boards").document(boardID).updateData([
            "memberIDs": memberIDs
        ])
    }

    func markGroupCompleted(groupID: String) async throws {
        try await db.collection("groups").document(groupID).updateData(["isCompleted": true])
    }

    func updateGroupRewards(groupID: String, rewards: [String], allBingoReward: String) async throws {
        try await db.collection("groups").document(groupID).updateData([
            "lineRewards": rewards,
            "allBingoReward": allBingoReward
        ])
    }

    // MARK: - Member

    func fetchMember(id: String) async throws -> Member? {
        let snapshot = try await db.collection("members").document(id).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: Member.self)
    }

    func fetchMembers(ids: [String]) async throws -> [String: Member] {
        var result: [String: Member] = [:]
        for id in ids {
            if let member = try? await db.collection("members").document(id).getDocument(as: Member.self) {
                result[id] = member
            }
        }
        return result
    }

    func updateMember(_ member: Member) async throws {
        guard let id = member.id else { return }
        try db.collection("members").document(id).setData(from: member, merge: true)
    }

    func updateGroupDetails(_ group: BingoGroup) async throws {
        try await db.collection("groups").document(group.id).updateData([
            "name": group.name
        ])
    }

    func deleteGroup(groupID: String) async throws {
        try await db.collection("groups").document(groupID).delete()
    }

    func leaveGroup(groupID: String, memberID: String) async throws {
        try await db.collection("groups").document(groupID).updateData([
            "memberIDs": FieldValue.arrayRemove([memberID])
        ])
    }

    func deleteMember(id: String) async throws {
        try await db.collection("members").document(id).delete()
    }

    // MARK: - FCM Token

    func updateFCMToken(memberID: String, token: String) async throws {
        try await db.collection("members").document(memberID).updateData([
            "fcmToken": token,
            "fcmTokenUpdatedAt": Date()
        ])
    }

    func updateLanguage(memberID: String, language: String) async throws {
        try await db.collection("members").document(memberID).updateData([
            "language": language
        ])
    }

    func clearFCMToken(memberID: String) async throws {
        try await db.collection("members").document(memberID).updateData([
            "fcmToken": FieldValue.delete(),
            "fcmTokenUpdatedAt": FieldValue.delete()
        ])
    }

    // MARK: - Notification Settings (방별 × 멤버별)

    func fetchNotificationSettings(groupID: String, memberID: String) async throws -> NotificationSettings {
        let ref = db.collection("groups").document(groupID)
            .collection("memberSettings").document(memberID)
        let snapshot = try await ref.getDocument()
        if snapshot.exists, let settings = try? snapshot.data(as: NotificationSettings.self) {
            return settings
        }
        return NotificationSettings()  // 기본값: 모든 알림 on
    }

    func saveNotificationSettings(_ settings: NotificationSettings,
                                   groupID: String, memberID: String) async throws {
        let ref = db.collection("groups").document(groupID)
            .collection("memberSettings").document(memberID)
        try ref.setData(from: settings, merge: true)
    }

}
