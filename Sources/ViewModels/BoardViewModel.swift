import Foundation
import UIKit
import FirebaseFirestore

@MainActor
final class BoardViewModel: ObservableObject {
    @Published var board: BingoBoard?
    @Published var group: BingoGroup
    @Published var completedLines: [BingoReward] = []
    @Published var memberProfiles: [String: Member] = [:]

    // 축하 트리거 (live — overlay에 직접 반영)
    @Published var newBingoCelebration: Int? = nil   // 새 빙고 달성 시 현재 줄 수
    @Published var showGameComplete: Bool = false     // 전체 완성
    @Published var showBingoResetToast: Bool = false  // 빙고 재설정 알림

    // 보류 중인 축하 (시트가 열려 있을 때 발동된 경우 → 시트 닫힌 후 승격)
    @Published var pendingBingoCelebration: Int? = nil
    @Published var pendingGameComplete: Bool = false

    // 완성된 줄에 속하는 셀 인덱스 → 라인 번호 (나중 라인이 겹치면 덮어씀)
    @Published var completedLineCells: [Int: Int] = [:]

    private var boardListener: ListenerRegistration?
    private var groupListener: ListenerRegistration?
    private var previousCompletedCount: Int = -1   // -1 = 미초기화
    private var previousAllCellsComplete: Bool = false
    /// 서버에서 마지막으로 받은 빙고판 — 저장 실패 시 화면을 이 상태로 되돌린다
    private var lastServerBoard: BingoBoard?

    enum BoardError: LocalizedError {
        case saveFailed
        var errorDescription: String? {
            Localization.isEnglish ? "Couldn't save. Please check your connection and try again."
                                   : "저장하지 못했어요. 인터넷 연결을 확인하고 다시 시도해주세요."
        }
    }

    init(group: BingoGroup) {
        self.group = group
    }

    func loadBoard() {
        groupListener = FirestoreService.shared.listenToGroup(id: group.id) { [weak self] updated in
            guard let self else { return }
            DispatchQueue.main.async {
                let previousMemberIDs = Set(self.group.memberIDs)
                let previousBoardID = self.group.boardID
                self.group = updated

                // boardID가 새로 생긴 경우 board 리스너 시작
                if self.board == nil, let boardID = updated.boardID, boardID != previousBoardID {
                    self.listenToBoard(boardID: boardID)
                }

                // 멤버 변경 감지 시 프로필 갱신 + board memberIDs 동기화
                if Set(updated.memberIDs) != previousMemberIDs {
                    Task { await self.loadMemberProfiles() }

                    if var board = self.board {
                        board.memberIDs = updated.memberIDs
                        self.board = board
                        Task {
                            try? await FirestoreService.shared.updateBoardMemberIDs(
                                boardID: board.id, memberIDs: updated.memberIDs
                            )
                        }
                        self.detectCompletedLines(board: board)
                    }
                }
            }
        }
        if let boardID = group.boardID {
            listenToBoard(boardID: boardID)
        } else {
            Task { await fetchOrCreateBoard() }
        }
        Task { await loadMemberProfiles() }
    }

    private func loadMemberProfiles() async {
        memberProfiles = (try? await FirestoreService.shared.fetchMembers(ids: group.memberIDs)) ?? [:]
    }

    private func fetchOrCreateBoard() async {
        do {
            let latestGroup = try await FirestoreService.shared.fetchGroup(by: group.id)
            if let boardID = latestGroup.boardID {
                group = latestGroup
                listenToBoard(boardID: boardID)
            } else {
                createDefaultBoard()
            }
        } catch {
            createDefaultBoard()
        }
    }

    private func listenToBoard(boardID: String) {
        boardListener?.remove()
        boardListener = FirestoreService.shared.listenToBoard(id: boardID) { [weak self] board in
            guard let self else { return }
            // Firestore board의 memberIDs는 오래된 값일 수 있으므로 항상 group의 최신 memberIDs로 동기화
            var syncedBoard = board
            syncedBoard.memberIDs = self.group.memberIDs
            self.lastServerBoard = syncedBoard
            self.board = syncedBoard
            self.detectCompletedLines(board: syncedBoard)
        }
    }

    // MARK: - 저장 공통

    /// 화면에 먼저 반영한 뒤, 서버의 최신 빙고판에 같은 변경을 적용해 저장한다.
    /// 다른 멤버의 동시 변경을 덮어쓰지 않는다. 저장된 최신 판을 반환하고, 실패하면 화면을 서버 상태로 되돌린 뒤 nil을 반환한다.
    @discardableResult
    private func applyBoardChange(_ change: @escaping (inout BingoBoard) -> Bool) async -> BingoBoard? {
        guard var local = board else { return nil }
        guard change(&local) else { return nil }
        board = local
        detectCompletedLines(board: local)

        do {
            var saved = try await FirestoreService.shared.mutateBoard(id: local.id, change)
            saved.memberIDs = group.memberIDs
            return saved
        } catch {
            #if DEBUG
            print("빙고판 저장 실패: \(error)")
            #endif
            if let serverBoard = lastServerBoard {
                board = serverBoard
                detectCompletedLines(board: serverBoard)
            }
            return nil
        }
    }

    /// 저장된 최신 판 기준으로 방의 완성 줄 수를 갱신 (빙고 달성 알림의 기준값)
    private func syncGroupLines(with savedBoard: BingoBoard) async {
        let count = Self.findCompletedLines(board: savedBoard, memberIDs: group.memberIDs).lines.count
        try? await FirestoreService.shared.updateGroupLines(groupID: group.id, count: count)
    }

    // MARK: - 미션 완료 / 취소

    func toggleCell(row: Int, col: Int, memberID: String) async {
        guard let current = board else { return }
        let cell = current.cell(row: row, col: col)
        let cellID = cell.id
        let key = BingoBoard.interactionKey(cellID: cellID, ownerID: memberID)
        let wasCompleted = cell.completedBy.contains(memberID)
        let now = Date()

        if wasCompleted, cell.proofImageURLs[memberID] != nil {
            // 완료 취소 시 인증 사진도 자동 삭제
            await StorageService.shared.deleteProofImage(
                groupID: group.id, cellID: cellID, memberID: memberID
            )
        }

        let saved = await applyBoardChange { board in
            if wasCompleted {
                let found = board.updateCell(id: cellID) { c in
                    c.completedBy.removeAll { $0 == memberID }
                    c.completedAt.removeValue(forKey: memberID)
                    c.proofImageURLs.removeValue(forKey: memberID)
                }
                board.cellReactions.removeValue(forKey: key)
                board.cellComments.removeValue(forKey: key)
                return found
            } else {
                return board.updateCell(id: cellID) { c in
                    if !c.completedBy.contains(memberID) {
                        c.completedBy.append(memberID)
                        c.completedAt[memberID] = now
                    }
                }
            }
        }
        if let saved { await syncGroupLines(with: saved) }
    }

    // MARK: - 인증 사진

    func uploadProofImage(row: Int, col: Int, memberID: String, image: UIImage) async throws {
        guard let current = board else { return }
        let cellID = current.cell(row: row, col: col).id
        let url = try await StorageService.shared.uploadProofImage(
            image, groupID: group.id, cellID: cellID, memberID: memberID
        )
        let saved = await applyBoardChange { board in
            board.updateCell(id: cellID) { c in
                c.proofImageURLs[memberID] = url
            }
        }
        if saved == nil { throw BoardError.saveFailed }
    }

    func deleteProofImage(row: Int, col: Int, memberID: String) async {
        guard let current = board else { return }
        let cellID = current.cell(row: row, col: col).id
        let key = BingoBoard.interactionKey(cellID: cellID, ownerID: memberID)
        await StorageService.shared.deleteProofImage(
            groupID: group.id, cellID: cellID, memberID: memberID
        )
        let saved = await applyBoardChange { board in
            let found = board.updateCell(id: cellID) { c in
                c.proofImageURLs.removeValue(forKey: memberID)
                c.completedBy.removeAll { $0 == memberID }
                c.completedAt.removeValue(forKey: memberID)
            }
            board.cellReactions.removeValue(forKey: key)
            board.cellComments.removeValue(forKey: key)
            return found
        }
        if let saved { await syncGroupLines(with: saved) }
    }

    // MARK: - 이모티콘 반응

    func toggleReaction(row: Int, col: Int, photoOwnerID: String,
                        reactorID: String, emoji: String) async {
        guard let current = board else { return }
        let key = BingoBoard.interactionKey(cellID: current.cell(row: row, col: col).id, ownerID: photoOwnerID)
        // 누른 시점의 화면 기준으로 "취소인지 / 남기기인지" 결정 → 서버 판에도 같은 동작 적용
        let removing = current.cellReactions[key]?[reactorID] == emoji

        await applyBoardChange { board in
            var reactions = board.cellReactions[key] ?? [:]
            if removing { reactions.removeValue(forKey: reactorID) }
            else { reactions[reactorID] = emoji }
            if reactions.isEmpty { board.cellReactions.removeValue(forKey: key) }
            else { board.cellReactions[key] = reactions }
            return true
        }
    }

    // MARK: - 댓글 반응

    func toggleCommentReaction(row: Int, col: Int, photoOwnerID: String,
                               commentID: String, reactorID: String, emoji: String) async {
        guard let current = board else { return }
        let key = BingoBoard.interactionKey(cellID: current.cell(row: row, col: col).id, ownerID: photoOwnerID)
        let currentComment = current.cellComments[key]?.first(where: { $0.id == commentID })
        let removing = currentComment?.reactions[reactorID] == emoji

        await applyBoardChange { board in
            var comments = board.cellComments[key] ?? []
            guard let idx = comments.firstIndex(where: { $0.id == commentID }) else { return false }
            if removing { comments[idx].reactions.removeValue(forKey: reactorID) }
            else { comments[idx].reactions[reactorID] = emoji }
            board.cellComments[key] = comments
            return true
        }
    }

    // MARK: - 댓글

    func addComment(row: Int, col: Int, photoOwnerID: String,
                    authorID: String, text: String) async {
        guard let current = board else { return }
        let trimmed = String(text.trimmingCharacters(in: .whitespaces).prefix(100))
        guard !trimmed.isEmpty else { return }
        let key = BingoBoard.interactionKey(cellID: current.cell(row: row, col: col).id, ownerID: photoOwnerID)
        // 재시도 시에도 같은 댓글(같은 id)이 들어가도록 밖에서 한 번만 생성
        let comment = CellComment(authorMemberID: authorID, text: trimmed)

        await applyBoardChange { board in
            var comments = board.cellComments[key] ?? []
            guard comments.count < 30, !comments.contains(where: { $0.id == comment.id }) else { return false }
            comments.append(comment)
            board.cellComments[key] = comments
            return true
        }
    }

    func editComment(row: Int, col: Int, photoOwnerID: String,
                     commentID: String, newText: String) async {
        guard let current = board else { return }
        let trimmed = String(newText.trimmingCharacters(in: .whitespaces).prefix(100))
        guard !trimmed.isEmpty else { return }
        let key = BingoBoard.interactionKey(cellID: current.cell(row: row, col: col).id, ownerID: photoOwnerID)

        await applyBoardChange { board in
            var comments = board.cellComments[key] ?? []
            guard let idx = comments.firstIndex(where: { $0.id == commentID }) else { return false }
            comments[idx].text = trimmed
            board.cellComments[key] = comments
            return true
        }
    }

    func deleteComment(row: Int, col: Int, photoOwnerID: String,
                       commentID: String) async {
        guard let current = board else { return }
        let key = BingoBoard.interactionKey(cellID: current.cell(row: row, col: col).id, ownerID: photoOwnerID)

        await applyBoardChange { board in
            var comments = board.cellComments[key] ?? []
            comments.removeAll { $0.id == commentID }
            if comments.isEmpty { board.cellComments.removeValue(forKey: key) }
            else { board.cellComments[key] = comments }
            return true
        }
    }

    // MARK: - 미션 내용 수정

    func updateCellTitle(row: Int, col: Int, title: String, description: String = "") async {
        guard let current = board else { return }
        let cellID = current.cell(row: row, col: col).id

        await applyBoardChange { board in
            board.updateCell(id: cellID) { c in
                c.title = title
                c.description = description
            }
        }
    }

    func updateRewards(_ rewards: [String], allBingoReward: String) async {
        try? await FirestoreService.shared.updateGroupRewards(
            groupID: group.id, rewards: rewards, allBingoReward: allBingoReward
        )
    }

    /// 보류 중인 축하를 실제 overlay로 승격시킨다.
    /// BoardView가 시트가 닫혔을 때(onDismiss) 또는 pending 값 변화 감지 시 호출.
    func triggerPendingCelebration() {
        if let count = pendingBingoCelebration {
            pendingBingoCelebration = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.newBingoCelebration = count
            }
        }
        if pendingGameComplete {
            pendingGameComplete = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showGameComplete = true
            }
        }
    }

    func markCompleted() async {
        try? await FirestoreService.shared.markGroupCompleted(groupID: group.id)
    }

    // MARK: - 완성 줄 감지

    /// 완성된 줄 목록과 "셀 인덱스 → 라인 번호" 표를 계산 (부수효과 없음)
    /// 겹치는 칸은 우위 순서(가로>세로>대각선)에 따라 덮어씌움
    private static func findCompletedLines(board: BingoBoard,
                                           memberIDs: [String]) -> (lines: [BingoReward], cellMap: [Int: Int]) {
        let size = board.size
        var lines: [BingoReward] = []
        var cellMap: [Int: Int] = [:]
        var lineNumber = 0

        func markLine(_ indices: [Int]) {
            indices.forEach { cellMap[$0] = lineNumber }
            lineNumber += 1
        }

        // 우위 순서: 대각선(낮은 번호) → 세로 → 가로(높은 번호)
        // 이렇게 하면 겹치는 셀은 가장 높은 lineNumber(가로)가 최종 표시됨

        // 1단계: 대각선 탐지
        if (0..<size).allSatisfy({ board.cell(row: $0, col: $0).isCompleted(for: memberIDs) }) {
            lines.append(BingoReward(lineIndex: 0, lineType: .diagonal, description: ""))
            markLine((0..<size).map { $0 * size + $0 })
        }
        if (0..<size).allSatisfy({ board.cell(row: $0, col: size - 1 - $0).isCompleted(for: memberIDs) }) {
            lines.append(BingoReward(lineIndex: 1, lineType: .diagonal, description: ""))
            markLine((0..<size).map { $0 * size + (size - 1 - $0) })
        }

        // 2단계: 세로 탐지
        for i in 0..<size {
            if (0..<size).allSatisfy({ board.cell(row: $0, col: i).isCompleted(for: memberIDs) }) {
                lines.append(BingoReward(lineIndex: i, lineType: .column, description: ""))
                markLine((0..<size).map { $0 * size + i })
            }
        }

        // 3단계: 가로 탐지 (마지막, lineNumber가 가장 높아서 겹치는 셀을 덮어씀)
        for i in 0..<size {
            if (0..<size).allSatisfy({ board.cell(row: i, col: $0).isCompleted(for: memberIDs) }) {
                lines.append(BingoReward(lineIndex: i, lineType: .row, description: ""))
                markLine((0..<size).map { i * size + $0 })
            }
        }

        return (lines, cellMap)
    }

    private func detectCompletedLines(board: BingoBoard) {
        let memberIDs = group.memberIDs  // board.memberIDs 대신 항상 최신 group.memberIDs 사용
        let (lines, cellMap) = Self.findCompletedLines(board: board, memberIDs: memberIDs)

        completedLines = lines
        completedLineCells = cellMap

        let newCount = lines.count
        let allCellsComplete = board.cells.allSatisfy { $0.isCompleted(for: memberIDs) }

        // 첫 로드 시엔 축하 없이 초기화
        guard previousCompletedCount != -1 else {
            previousCompletedCount = newCount
            previousAllCellsComplete = allCellsComplete
            return
        }

        if allCellsComplete && !previousAllCellsComplete {
            // 모든 셀 전원 완료 → 전체 완성 (시트 닫힌 후 실제 발동은 BoardView가 결정)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.pendingGameComplete = true
            }
        } else if newCount > previousCompletedCount {
            // 새 빙고 줄 달성 (시트 닫힌 후 실제 발동은 BoardView가 결정)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.pendingBingoCelebration = newCount
            }
        } else if newCount < previousCompletedCount {
            // 빙고가 취소됨 (멤버 추가 등으로 인해)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showBingoResetToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.showBingoResetToast = false
                }
            }
        }

        previousAllCellsComplete = allCellsComplete
        previousCompletedCount = newCount
    }

    private func createDefaultBoard() {
        let size = group.boardSize
        let count = size * size
        let cells = (0..<count).map { _ in BingoCell(title: "") }
        let newBoard = BingoBoard(
            title: group.name, size: size, cells: cells,
            memberIDs: group.memberIDs, leaderID: group.leaderID
        )
        self.board = newBoard
        Task {
            do {
                try await FirestoreService.shared.createBoard(newBoard)
                try await FirestoreService.shared.updateGroupBoardID(groupID: group.id, boardID: newBoard.id)
                // 만든 판의 실시간 업데이트 수신 시작 (다른 멤버 변경 반영 + 저장 실패 시 되돌릴 기준)
                listenToBoard(boardID: newBoard.id)
            } catch { }
        }
    }

    deinit {
        boardListener?.remove()
        groupListener?.remove()
    }
}
