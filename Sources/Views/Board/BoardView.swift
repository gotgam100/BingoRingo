import SwiftUI

struct BoardView: View {
    let group: BingoGroup
    @StateObject private var boardVM: BoardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedIndex: CellIndex?

    init(group: BingoGroup) {
        self.group = group
        _boardVM = StateObject(wrappedValue: BoardViewModel(group: group))
    }

    var body: some View {
        ZStack {
            BRColors.background.ignoresSafeArea()

            VStack(spacing: 12) {
                if !boardVM.completedLines.isEmpty {
                    bingoCounterBanner
                }

                if let board = boardVM.board {
                    bingoGrid(board: board)
                        .padding(.horizontal, 12)
                    memberProgressView(board: board)
                        .padding(.horizontal, 12)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.top, 8)
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { boardVM.loadBoard() }
        .sheet(item: $selectedIndex) { index in
            if let board = boardVM.board {
                CellDetailView(
                    cell: board.cell(row: index.row, col: index.col),
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
        HStack(spacing: 8) {
            Rectangle()
                .fill(BRColors.orange)
                .frame(width: 4)
                .clipShape(Capsule())
            Text("BINGO \(boardVM.completedLines.count)줄 완성!")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(BRColors.cobaltBlue)
            Spacer()
        }
        .frame(height: 36)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(BRColors.cobaltBlue.opacity(0.08))
        )
        .padding(.horizontal, 12)
    }

    private func bingoGrid(board: BingoBoard) -> some View {
        let size = board.size
        let memberID = authViewModel.currentMember?.id ?? ""

        return GeometryReader { geo in
            let gap: CGFloat = 4
            let cellSize = (geo.size.width - gap * CGFloat(size - 1)) / CGFloat(size)

            VStack(spacing: gap) {
                ForEach(0..<size, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<size, id: \.self) { col in
                            BingoCellView(
                                cell: board.cell(row: row, col: col),
                                memberIDs: board.memberIDs,
                                currentMemberID: memberID,
                                size: cellSize
                            )
                            .onTapGesture {
                                selectedIndex = CellIndex(row: row, col: col)
                            }
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func memberProgressView(board: BingoBoard) -> some View {
        let total = board.size * board.size
        return VStack(alignment: .leading, spacing: 10) {
            Text("멤버 현황")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                ForEach(Array(board.memberIDs.enumerated()), id: \.element) { idx, id in
                    let completed = board.cells.filter { $0.completedBy.contains(id) }.count
                    let isMe = id == authViewModel.currentMember?.id
                    let color = [BRColors.cobaltBlue, BRColors.orange, BRColors.red, BRColors.beige][idx % 4]

                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .stroke(BRColors.lightGray, lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: CGFloat(completed) / CGFloat(total))
                                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("\(completed)")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundStyle(color)
                        }
                        .frame(width: 48, height: 48)

                        Text(isMe ? "나" : "멤버\(idx + 1)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(isMe ? color : .secondary)
                    }
                }
                Spacer()
            }
        }
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
