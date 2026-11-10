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

    /// 서버의 최신 빙고판을 읽어 `mutate`로 고친 뒤 저장한다.
    /// - 여러 멤버가 동시에 저장해도 서로의 기록을 덮어쓰지 않는다 (충돌 시 Firestore가 자동 재시도).
    /// - cells / cellReactions / cellComments 필드만 통째로 교체하므로, 지운 반응·댓글도 서버에서 실제로 지워진다.
    /// - 저장 형식(필드 이름, 타입)은 기존과 같다.
    /// - `mutate`는 재시도 때 여러 번 불릴 수 있으므로 같은 입력에 같은 결과를 내야 한다. false를 반환하면 저장하지 않는다.
    @discardableResult
    func mutateBoard(id boardID: String,
                     _ mutate: @escaping (inout BingoBoard) -> Bool) async throws -> BingoBoard {
        let ref = db.collection("boards").document(boardID)
        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(ref)
                var board = try snapshot.data(as: BingoBoard.self)
                guard mutate(&board) else { return board }
                let encoded = try Firestore.Encoder().encode(board)
                transaction.updateData([
                    "cells": encoded["cells"] ?? [],
                    "cellReactions": encoded["cellReactions"] ?? [:],
                    "cellComments": encoded["cellComments"] ?? [:]
                ], forDocument: ref)
                return board
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let board = result as? BingoBoard else { throw ServiceError.unexpectedResult }
        return board
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

    enum JoinResult: String {
        case joined, alreadyMember, full
    }

    /// 초대 코드로 방 참여 — 멤버 목록에 나만 추가한다 (방 문서 전체를 덮어쓰지 않음).
    /// 여러 명이 동시에 참여해도 서로 빠지지 않고, 인원 제한도 서버 최신 값 기준으로 확인한다.
    func joinGroup(groupID: String, memberID: String, maxMembers: Int = 10) async throws -> JoinResult {
        let ref = db.collection("groups").document(groupID)
        let result = try await db.runTransaction { transaction, errorPointer -> Any? in
            do {
                let snapshot = try transaction.getDocument(ref)
                let memberIDs = snapshot.data()?["memberIDs"] as? [String] ?? []
                if memberIDs.contains(memberID) { return JoinResult.alreadyMember.rawValue }
                if memberIDs.count >= maxMembers { return JoinResult.full.rawValue }
                transaction.updateData([
                    "memberIDs": FieldValue.arrayUnion([memberID])
                ], forDocument: ref)
                return JoinResult.joined.rawValue
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        guard let raw = result as? String, let joinResult = JoinResult(rawValue: raw) else {
            throw ServiceError.unexpectedResult
        }
        return joinResult
    }

    /// 계정 삭제 전 호출 — 참여 중인 모든 방의 멤버 목록에서 나를 뺀다.
    /// 빠지지 않으면 남은 멤버들이 그 방에서 빙고를 달성할 수 없게 된다.
    func removeMemberFromAllGroups(memberID: String) async throws {
        let snapshot = try await db.collection("groups")
            .whereField("memberIDs", arrayContains: memberID)
            .getDocuments()
        for doc in snapshot.documents {
            try await doc.reference.updateData([
                "memberIDs": FieldValue.arrayRemove([memberID])
            ])
            if let boardID = doc.data()["boardID"] as? String, !boardID.isEmpty {
                try? await db.collection("boards").document(boardID).updateData([
                    "memberIDs": FieldValue.arrayRemove([memberID])
                ])
            }
        }
    }

    enum ServiceError: LocalizedError {
        case unexpectedResult
        var errorDescription: String? {
            Localization.isEnglish ? "Couldn't save. Please try again." : "저장하지 못했어요. 다시 시도해주세요."
        }
    }

    func deleteMember(id: String) async throws {
        try await db.collection("members").document(id).delete()
    }

    // MARK: - FCM Token

    func updateFCMToken(memberID: String, token: String) async throws {
        try await db.collection("members").document(memberID).setData([
            "fcmToken": token,
            "fcmTokenUpdatedAt": FieldValue.serverTimestamp()
        ], merge: true)
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
