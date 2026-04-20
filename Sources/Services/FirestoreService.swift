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

    // MARK: - Cell

    func checkCell(boardID: String, cellID: String, memberID: String) async throws {
        let ref = db.collection("boards").document(boardID)
        try await ref.updateData([
            "cells": FieldValue.arrayUnion([["completedBy": memberID, "cellID": cellID]])
        ])
    }
}
