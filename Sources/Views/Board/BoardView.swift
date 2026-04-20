import SwiftUI

struct BoardView: View {
    let group: BingoGroup
    @StateObject private var boardVM: BoardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedCell: (Int, Int)?

    init(group: BingoGroup) {
        self.group = group
        _boardVM = StateObject(wrappedValue: BoardViewModel(group: group))
    }

    var body: some View {
        ZStack {
            BRColors.background.ignoresSafeArea()

            VStack(spacing: 16) {
                // 빙고 카운터
                if !boardVM.completedLines.isEmpty {
                    bingoCounterBanner
                }

                // 빙고 그리드
                if let board = boardVM.board {
                    bingoGrid(board: board)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // 멤버 현황
                if let board = boardVM.board {
                    memberProgressView(board: board)
                }
            }
            .padding()
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { boardVM.loadBoard() }
        .sheet(item: Binding(
            get: { selectedCell.map { CellIndex(row: $0.0, col: $0.1) } },
            set: { _ in selectedCell = nil }
        )) { index in
            if let board = boardVM.board {
                CellDetailView(
                    cell: board.cells[index.row][index.col],
                    memberIDs: board.memberIDs,
                    currentMemberID: authViewModel.currentMember?.id ?? ""
                ) {
                    Task {
                        await boardVM.toggleCell(
                            row: index.row,
                            col: index.col,
                            memberID: authViewModel.currentMember?.id ?? ""
                        )
                    }
                }
            }
        }
    }

    private var bingoCounterBanner: some View {
        HStack {
            Text("🎉 BINGO \(boardVM.completedLines.count)줄 완성!")
                .font(BRTypography.cellTitle)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(BRColors.cobaltBlue)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func bingoGrid(board: BingoBoard) -> some View {
        let size = board.size
        let memberID = authViewModel.currentMember?.id ?? ""

        return GeometryReader { geo in
            let cellSize = (geo.size.width - CGFloat(size - 1) * 4) / CGFloat(size)
            VStack(spacing: 4) {
                ForEach(0..<size, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<size, id: \.self) { col in
                            BingoCellView(
                                cell: board.cells[row][col],
                                memberIDs: board.memberIDs,
                                currentMemberID: memberID,
                                size: cellSize
                            )
                            .onTapGesture {
                                selectedCell = (row, col)
                            }
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func memberProgressView(board: BingoBoard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("멤버 현황")
                .font(BRTypography.cellTitle)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                ForEach(board.memberIDs, id: \.self) { id in
                    let completed = board.cells.flatMap { $0 }.filter { $0.completedBy.contains(id) }.count
                    let total = board.size * board.size
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(BRColors.lightGray, lineWidth: 3)
                            Circle()
                                .trim(from: 0, to: CGFloat(completed) / CGFloat(total))
                                .stroke(BRColors.cobaltBlue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("\(completed)")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(width: 44, height: 44)
                        Text(id == authViewModel.currentMember?.id ? "나" : "멤버")
                            .font(BRTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 6)
        )
    }
}

struct CellIndex: Identifiable {
    let row: Int
    let col: Int
    var id: String { "\(row)-\(col)" }
}
