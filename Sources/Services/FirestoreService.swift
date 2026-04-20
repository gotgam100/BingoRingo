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

    func updateCellTitle(boardID: String, cellIndex: Int, title: String) async throws {
        let board = try await db.collection("boards").document(boardID).getDocument(as: BingoBoard.self)
        var cells = board.cells
        cells[cellIndex].title = title
        let encoded = try Firestore.Encoder().encode(cells)
        try await db.collection("boards").document(boardID).updateData(["cells": encoded])
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
