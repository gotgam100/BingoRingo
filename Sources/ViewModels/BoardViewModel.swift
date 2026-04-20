import Foundation
import FirebaseFirestore

@MainActor
final class BoardViewModel: ObservableObject {
    @Published var board: BingoBoard?
    @Published var completedLines: [BingoReward] = []
    @Published var isLoading: Bool = false

    private var listener: ListenerRegistration?
    let group: BingoGroup

    init(group: BingoGroup) {
        self.group = group
    }

    func loadBoard() {
        guard let boardID = group.boardID else {
            createDefaultBoard()
            return
        }
        listener = FirestoreService.shared.listenToBoard(id: boardID) { [weak self] board in
            guard let self else { return }
            self.board = board
            self.detectCompletedLines(board: board)
        }
    }

    func toggleCell(row: Int, col: Int, memberID: String) async {
        guard var board else { return }
        var cell = board.cell(row: row, col: col)

        if cell.completedBy.contains(memberID) {
            cell.completedBy.removeAll { $0 == memberID }
        } else {
            cell.completedBy.append(memberID)
        }
        board.setCell(cell, row: row, col: col)
        self.board = board
        detectCompletedLines(board: board)
        try? await FirestoreService.shared.updateBoard(board)
        try? await FirestoreService.shared.updateGroupLines(
            groupID: group.id,
            count: completedLines.count
        )
    }

    private func createDefaultBoard() {
        let size = 5
        let placeholders = [
            "운동하기", "책 읽기", "영화 보기", "요리하기", "산책하기",
            "친구 만나기", "새로운 카페", "일찍 일어나기", "물 2L 마시기", "명상하기",
            "감사 일기", "새 음악 듣기", "봉사활동", "취미 배우기", "FREE",
            "사진 찍기", "편지 쓰기", "낮잠 자기", "게임하기", "드라이브",
            "미술관 가기", "노래 부르기", "청소하기", "요가하기", "별보기"
        ]

        let cells = (0..<(size * size)).map { i in
            BingoCell(title: placeholders[i])
        }

        let newBoard = BingoBoard(
            title: group.name,
            size: size,
            cells: cells,
            rewards: [],
            memberIDs: group.memberIDs,
            leaderID: group.leaderID
        )
        self.board = newBoard
        Task { try? await FirestoreService.shared.createBoard(newBoard) }
    }

    private func detectCompletedLines(board: BingoBoard) {
        let size = board.size
        var lines: [BingoReward] = []

        for i in 0..<size {
            if (0..<size).allSatisfy({ board.cell(row: i, col: $0).isCompleted(for: board.memberIDs) }) {
                lines.append(BingoReward(lineIndex: i, lineType: .row, description: ""))
            }
            if (0..<size).allSatisfy({ board.cell(row: $0, col: i).isCompleted(for: board.memberIDs) }) {
                lines.append(BingoReward(lineIndex: i, lineType: .column, description: ""))
            }
        }
        if (0..<size).allSatisfy({ board.cell(row: $0, col: $0).isCompleted(for: board.memberIDs) }) {
            lines.append(BingoReward(lineIndex: 0, lineType: .diagonal, description: ""))
        }
        if (0..<size).allSatisfy({ board.cell(row: $0, col: size - 1 - $0).isCompleted(for: board.memberIDs) }) {
            lines.append(BingoReward(lineIndex: 1, lineType: .diagonal, description: ""))
        }
        completedLines = lines
    }

    deinit {
        listener?.remove()
    }
}
