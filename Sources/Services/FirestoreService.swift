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

    func updateCellTitle(boardID: String, cellIndex: Int, title: String, description: String = "") async throws {
        let board = try await db.collection("boards").document(boardID).getDocument(as: BingoBoard.self)
        var cells = board.cells
        cells[cellIndex].title = title
        cells[cellIndex].description = description
        let encoded = try Firestore.Encoder().encode(cells)
        try await db.collection("boards").document(boardID).updateData(["cells": encoded])
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

    // MARK: - Cell

    func checkCell(boardID: String, cellID: String, memberID: String) async throws {
        let ref = db.collection("boards").document(boardID)
        try await ref.updateData([
            "cells": FieldValue.arrayUnion([["completedBy": memberID, "cellID": cellID]])
        ])
    }
}
