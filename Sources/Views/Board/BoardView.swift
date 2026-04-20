import SwiftUI

struct BoardView: View {
    let group: BingoGroup
    @StateObject private var boardVM: BoardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedIndex: CellIndex?

    private let memberColors: [Color] = [BRColors.blue, BRColors.red, BRColors.green, BRColors.yellow]

    init(group: BingoGroup) {
        self.group = group
        _boardVM = StateObject(wrappedValue: BoardViewModel(group: group))
    }

    var body: some View {
        ZStack {
            // 컬러풀 배경
            boardBackground

            VStack(spacing: 0) {
                // 빙고 카운터
                if !boardVM.completedLines.isEmpty {
                    bingoCounterBanner
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                }

                if let board = boardVM.board {
                    // 그리드
                    bingoGrid(board: board)
                        .padding(.horizontal, 12)
                        .padding(.top, 12)

                    // 멤버 범례
                    memberLegend(board: board)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)

                    // 멤버 진행률
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
        .sheet(item: $selectedIndex) { index in
            if let board = boardVM.board {
                CellDetailView(
                    cell: board.cell(row: index.row, col: index.col),
                    memberIDs: board.memberIDs,
                    currentMemberID: authViewModel.currentMember?.id ?? ""
                ) {
                    Task {
                        await boardVM.toggleCell(
                            row: index.row, col: index.col,
                            memberID: authViewModel.currentMember?.id ?? ""
                        )
                    }
                }
            }
        }
    }

    // MARK: - 배경
    private var boardBackground: some View {
        ZStack {
            BRColors.blue.ignoresSafeArea()

            Blob1()
                .fill(BRColors.red.opacity(0.5))
                .frame(width: 220, height: 220)
                .offset(x: 150, y: -180)
                .ignoresSafeArea()

            Blob2()
                .fill(BRColors.green.opacity(0.35))
                .frame(width: 180, height: 180)
                .offset(x: -140, y: 100)
                .ignoresSafeArea()

            Circle()
                .fill(BRColors.yellow.opacity(0.4))
                .frame(width: 100, height: 100)
                .offset(x: 140, y: 300)
                .ignoresSafeArea()
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
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(BRColors.yellow)
                .shadow(color: BRColors.yellow.opacity(0.4), radius: 8, y: 3)
        )
    }

    // MARK: - 빙고 그리드
    private func bingoGrid(board: BingoBoard) -> some View {
        let size = board.size
        let memberID = authViewModel.currentMember?.id ?? ""

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

    // MARK: - 멤버 범례 (점 색상 설명)
    private func memberLegend(board: BingoBoard) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(board.memberIDs.enumerated()), id: \.element) { idx, id in
                let color = memberColors[idx % memberColors.count]
                let isMe = id == authViewModel.currentMember?.id

                HStack(spacing: 5) {
                    Circle()
                        .fill(color)
                        .frame(width: 10, height: 10)
                    Text(isMe ? "나" : "멤버\(idx + 1)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }

            Spacer()

            // 범례 설명
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle().fill(BRColors.lightGray).frame(width: 8, height: 8)
                    Text("미완료")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                HStack(spacing: 4) {
                    Circle().fill(BRColors.red).frame(width: 8, height: 8)
                    Text("완료")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
    }

    // MARK: - 멤버 진행률
    private func memberProgressView(board: BingoBoard) -> some View {
        let total = board.size * board.size

        return HStack(spacing: 12) {
            ForEach(Array(board.memberIDs.enumerated()), id: \.element) { idx, id in
                let completed = board.cells.filter { $0.completedBy.contains(id) }.count
                let isMe = id == authViewModel.currentMember?.id
                let color = memberColors[idx % memberColors.count]

                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: CGFloat(completed) / CGFloat(max(total, 1)))
                            .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(completed)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 46, height: 46)

                    Text(isMe ? "나" : "멤버\(idx + 1)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(isMe ? color : .white.opacity(0.7))
                }
            }
            Spacer()

            // 전체 빙고 수
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.12))
        )
    }
}

struct CellIndex: Identifiable {
    let row: Int
    let col: Int
    var id: String { "\(row)-\(col)" }
}
