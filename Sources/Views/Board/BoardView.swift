import SwiftUI

struct BoardView: View {
    let group: BingoGroup
    @StateObject private var boardVM: BoardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedIndex: CellIndex?
    @State private var editingIndex: CellIndex?

    private let memberColors: [Color] = [BRColors.blue, BRColors.red, BRColors.green, BRColors.yellow]

    private var memberID: String { authViewModel.currentMember?.id ?? "" }
    private var isLeader: Bool { group.leaderID == memberID }

    init(group: BingoGroup) {
        self.group = group
        _boardVM = StateObject(wrappedValue: BoardViewModel(group: group))
    }

    var body: some View {
        ZStack {
            boardBackground

            VStack(spacing: 0) {
                if !boardVM.completedLines.isEmpty {
                    bingoCounterBanner
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                if let board = boardVM.board {
                    bingoGrid(board: board)
                        .padding(.horizontal, 12)
                        .padding(.top, 12)

                    memberLegend(board: board)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)

                    memberProgressView(board: board)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                } else {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { boardVM.loadBoard() }
        // 셀 상세 시트
        .sheet(item: $selectedIndex) { index in
            if let board = boardVM.board {
                CellDetailView(
                    cell: board.cell(row: index.row, col: index.col),
                    memberIDs: board.memberIDs,
                    currentMemberID: memberID
                ) {
                    Task { await boardVM.toggleCell(row: index.row, col: index.col, memberID: memberID) }
                }
            }
        }
        // 제목 편집 시트 (방장 전용)
        .sheet(item: $editingIndex) { index in
            if let board = boardVM.board {
                CellEditSheet(
                    currentTitle: board.cell(row: index.row, col: index.col).title
                ) { newTitle in
                    Task { await boardVM.updateCellTitle(row: index.row, col: index.col, title: newTitle) }
                }
            }
        }
    }

    // MARK: - 배경
    private var boardBackground: some View {
        ZStack {
            BRColors.blue.ignoresSafeArea()
            Blob1().fill(BRColors.red.opacity(0.5)).frame(width: 220, height: 220)
                .offset(x: 150, y: -180).ignoresSafeArea()
            Blob2().fill(BRColors.green.opacity(0.35)).frame(width: 180, height: 180)
                .offset(x: -140, y: 100).ignoresSafeArea()
            Circle().fill(BRColors.yellow.opacity(0.4)).frame(width: 100, height: 100)
                .offset(x: 140, y: 300).ignoresSafeArea()
        }
    }

    // MARK: - 빙고 카운터
    private var bingoCounterBanner: some View {
        HStack(spacing: 10) {
            Text("🎉")
                .font(.system(size: 20))
            Text("BINGO \(boardVM.completedLines.count)줄 완성!")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(BRColors.blue)
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(BRColors.yellow)
            .shadow(color: BRColors.yellow.opacity(0.4), radius: 8, y: 3))
    }

    // MARK: - 그리드
    private func bingoGrid(board: BingoBoard) -> some View {
        let size = board.size

        return GeometryReader { geo in
            let gap: CGFloat = 5
            let cellSize = (geo.size.width - gap * CGFloat(size - 1)) / CGFloat(size)

            VStack(spacing: gap) {
                ForEach(0..<size, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<size, id: \.self) { col in
                            BingoCellView(
                                cell: board.cell(row: row, col: col),
                                memberIDs: board.memberIDs,
                                currentMemberID: memberID,
                                isLeader: isLeader,
                                size: cellSize,
                                onTap: { selectedIndex = CellIndex(row: row, col: col) },
                                onEdit: { editingIndex = CellIndex(row: row, col: col) },
                                onToggle: {
                                    Task { await boardVM.toggleCell(row: row, col: col, memberID: memberID) }
                                }
                            )
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - 멤버 범례
    private func memberLegend(board: BingoBoard) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(board.memberIDs.enumerated()), id: \.element) { idx, id in
                let color = memberColors[idx % memberColors.count]
                HStack(spacing: 5) {
                    Circle().fill(color).frame(width: 10, height: 10)
                    Text(id == memberID ? "나" : "멤버\(idx + 1)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            Spacer()
            if isLeader {
                Label("방장", systemImage: "crown.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(BRColors.yellow)
            }
        }
    }

    // MARK: - 멤버 진행률
    private func memberProgressView(board: BingoBoard) -> some View {
        let total = board.size * board.size
        return HStack(spacing: 12) {
            ForEach(Array(board.memberIDs.enumerated()), id: \.element) { idx, id in
                let completed = board.cells.filter { $0.completedBy.contains(id) }.count
                let color = memberColors[idx % memberColors.count]
                VStack(spacing: 6) {
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.2), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: CGFloat(completed) / CGFloat(max(total, 1)))
                            .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(completed)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 46, height: 46)
                    Text(id == memberID ? "나" : "멤버\(idx + 1)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(id == memberID ? color : .white.opacity(0.7))
                }
            }
            Spacer()
            VStack(spacing: 4) {
                Text("\(boardVM.completedLines.count)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(BRColors.yellow)
                Text("빙고")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.12)))
    }
}

struct CellIndex: Identifiable {
    let row: Int; let col: Int
    var id: String { "\(row)-\(col)" }
}
