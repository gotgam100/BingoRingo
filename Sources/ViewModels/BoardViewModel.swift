import Foundation
import FirebaseFirestore

@MainActor
final class BoardViewModel: ObservableObject {
    @Published var board: BingoBoard?
    @Published var group: BingoGroup
    @Published var completedLines: [BingoReward] = []
    @Published var memberProfiles: [String: Member] = [:]

    // 축하 트리거
    @Published var newBingoCelebration: Int? = nil   // 새 빙고 달성 시 현재 줄 수
    @Published var showGameComplete: Bool = false     // 전체 완성
    @Published var showBingoResetToast: Bool = false  // 빙고 재설정 알림

    // 완성된 줄에 속하는 셀 인덱스 → 라인 번호 (나중 라인이 겹치면 덮어씀)
    @Published var completedLineCells: [Int: Int] = [:]

    private var boardListener: ListenerRegistration?
    private var groupListener: ListenerRegistration?
    private var previousCompletedCount: Int = -1  // -1 = 미초기화

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
            self.board = syncedBoard
            self.detectCompletedLines(board: syncedBoard)
        }
    }

    func toggleCell(row: Int, col: Int, memberID: String) async {
        guard var board else { return }
        var cell = board.cell(row: row, col: col)
        if cell.completedBy.contains(memberID) {
            cell.completedBy.removeAll { $0 == memberID }
            cell.completedAt.removeValue(forKey: memberID)
        } else {
            cell.completedBy.append(memberID)
            cell.completedAt[memberID] = Date()
        }
        board.setCell(cell, row: row, col: col)
        self.board = board
        detectCompletedLines(board: board)
        try? await FirestoreService.shared.updateBoard(board)
        try? await FirestoreService.shared.updateGroupLines(groupID: group.id, count: completedLines.count)
    }

    func updateCellTitle(row: Int, col: Int, title: String, description: String = "") async {
        guard var board else { return }

        var cell = board.cell(row: row, col: col)
        cell.title = title
        cell.description = description
        board.setCell(cell, row: row, col: col)
        self.board = board

        do {
            try await FirestoreService.shared.updateBoard(board)
        } catch {
            print("❌ Cell title update error: \(error)")
        }
    }

    func updateRewards(_ rewards: [String], allBingoReward: String) async {
        try? await FirestoreService.shared.updateGroupRewards(
            groupID: group.id, rewards: rewards, allBingoReward: allBingoReward
        )
    }

    func markCompleted() async {
        try? await FirestoreService.shared.markGroupCompleted(groupID: group.id)
    }

    // MARK: - 완성 줄 감지

    private func detectCompletedLines(board: BingoBoard) {
        let size = board.size
        let memberIDs = group.memberIDs  // board.memberIDs 대신 항상 최신 group.memberIDs 사용
        var lines: [BingoReward] = []
        // 셀 인덱스 → 라인 번호. 겹치는 칸은 우위 순서(가로>세로>대각선)에 따라 덮어씌움
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

        completedLines = lines
        completedLineCells = cellMap

        let newCount = lines.count
        let target = group.boardSize

        // 첫 로드 시엔 축하 없이 초기화
        guard previousCompletedCount != -1 else {
            previousCompletedCount = newCount
            return
        }

        if newCount > previousCompletedCount {
            if newCount >= target {
                // 전체 완성
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.showGameComplete = true
                }
            } else {
                // 새 빙고 달성
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.newBingoCelebration = newCount
                }
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
        previousCompletedCount = newCount
    }

    private func createDefaultBoard() {
        let size = group.boardSize
        let count = size * size
        let cells = (0..<count).map { _ in BingoCell(title: "") }
        let newBoard = BingoBoard(
            title: group.name, size: size, cells: cells,
            rewards: [], memberIDs: group.memberIDs, leaderID: group.leaderID
        )
        self.board = newBoard
        Task {
            do {
                try await FirestoreService.shared.createBoard(newBoard)
                try await FirestoreService.shared.updateGroupBoardID(groupID: group.id, boardID: newBoard.id)
            } catch {
                print("❌ Board creation error: \(error)")
            }
        }
    }

    deinit {
        boardListener?.remove()
        groupListener?.remove()
    }
}
