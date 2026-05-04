import SwiftUI
import FirebaseAuth

struct BoardView: View {
    @StateObject private var boardVM: BoardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex: CellIndex?
    @State private var editingIndex: CellIndex?
    @State private var showRewardEdit = false
    @State private var copiedInviteCode: String?
    @State private var navigateTo: BingoGroup? = nil

    let allGroups: [BingoGroup]

    private let memberColors: [Color] = [
        BRColors.primary,
        BRColors.particlePink,
        BRColors.particleCyan,
        Color(hex: "#8B2BE2"),
    ]

    // 빙고 라인별 색상 팔레트 (최대 12줄 대응)
    static let lineColors: [Color] = [
        Color(hex: "#FF9500"), // 주황
        Color(hex: "#C8184B"), // 핑크-레드
        Color(hex: "#00B4D8"), // 시안
        Color(hex: "#8B2BE2"), // 보라
        Color(hex: "#FFD700"), // 노랑
        Color(hex: "#1A7A4A"), // 초록
        Color(hex: "#E64A19"), // 주황-빨강
        Color(hex: "#00897B"), // 청록
        Color(hex: "#FF9500"), Color(hex: "#C8184B"), Color(hex: "#00B4D8"), Color(hex: "#8B2BE2"),
    ]

    private var memberID: String {
        authViewModel.currentMember?.id ?? Auth.auth().currentUser?.uid ?? ""
    }
    private var isLeader: Bool { boardVM.group.leaderID == memberID }

    init(group: BingoGroup, allGroups: [BingoGroup] = []) {
        _boardVM = StateObject(wrappedValue: BoardViewModel(group: group))
        self.allGroups = allGroups
    }

    var body: some View {
        ZStack {
            BRColors.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 보상 섹션
                    rewardSection
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                    if let board = boardVM.board {
                        bingoGrid(board: board)
                            .padding(.horizontal, 12)
                            .padding(.top, 20)

                        Text(Localization.isEnglish
                             ? "Tap a mission to view details and complete with proof photo."
                             : "미션을 탭하면 상세 창에서 인증 사진과 함께 완료할 수 있어요.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(BRColors.onSurfaceMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 10)

                        memberSection(board: board)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 32)
                    } else {
                        ProgressView()
                            .tint(BRColors.primary)
                            .frame(maxWidth: .infinity, minHeight: 300)
                    }
                }
            }
        }
        .navigationTitle(boardVM.group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarTitleMenu {
            let others = allGroups.filter { $0.id != boardVM.group.id }
            if others.isEmpty {
                Text(Localization.isEnglish ? "No other rooms" : "다른 방이 없어요")
            } else {
                ForEach(others) { group in
                    Button {
                        navigateTo = group
                    } label: {
                        Label(group.name, systemImage: "rectangle.grid.2x2")
                    }
                }
            }
        }
        .navigationDestination(item: $navigateTo) { group in
            BoardView(group: group, allGroups: allGroups)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = boardVM.group.inviteCode
                    copiedInviteCode = boardVM.group.inviteCode
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        copiedInviteCode = nil
                    }
                } label: {
                    Image(systemName: "link.circle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                }
            }
        }
        .onAppear { boardVM.loadBoard() }
        .onChange(of: boardVM.board) {
            // 보드 데이터 도착 즉시 모든 인증사진 백그라운드 프리패치
            guard let board = boardVM.board else { return }
            let urls = board.cells.flatMap { $0.proofImageURLs.values }
            CachedAsyncImage.prefetch(urls: urls)
        }
        .sheet(item: $selectedIndex) { index in
            if let board = boardVM.board {
                CellDetailView(
                    cell: board.cell(row: index.row, col: index.col),
                    row: index.row,
                    col: index.col,
                    memberIDs: boardVM.group.memberIDs,
                    currentMemberID: memberID,
                    boardVM: boardVM
                ) {
                    Task { await boardVM.toggleCell(row: index.row, col: index.col, memberID: memberID) }
                }
            }
        }
        .sheet(item: $editingIndex) { index in
            if let board = boardVM.board {
                let cell = board.cell(row: index.row, col: index.col)
                CellEditSheet(
                    currentTitle: cell.title,
                    currentDescription: cell.description
                ) { newTitle, newDescription in
                    Task { await boardVM.updateCellTitle(row: index.row, col: index.col, title: newTitle, description: newDescription) }
                }
            }
        }
        .sheet(isPresented: $showRewardEdit) {
            RewardEditSheet(
                rewards: boardVM.group.lineRewards,
                allBingoReward: boardVM.group.allBingoReward,
                size: boardVM.group.boardSize,
                isReadOnly: !isLeader
            ) { updated, allBingo in
                Task { await boardVM.updateRewards(updated, allBingoReward: allBingo) }
            }
        }
        .overlay {
            if let count = boardVM.newBingoCelebration {
                BingoCelebrationOverlay(count: count) {
                    withAnimation { boardVM.newBingoCelebration = nil }
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            }
        }
        .overlay {
            if boardVM.showGameComplete {
                GameCompleteOverlay(
                    groupName: boardVM.group.name,
                    onContinue: {
                        withAnimation { boardVM.showGameComplete = false }
                    },
                    onFinish: {
                        boardVM.showGameComplete = false
                        Task {
                            await boardVM.markCompleted()
                            dismiss()
                        }
                    }
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
        }
        .overlay(alignment: .top) {
            if boardVM.showBingoResetToast {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BRColors.tertiary)
                        Text(Localization.Board.bingoReset)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BRColors.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(BRColors.tertiary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(16)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .overlay(alignment: .top) {
            if copiedInviteCode != nil {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BRColors.primary)
                        Text(Localization.Board.inviteCodeCopied)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BRColors.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(BRColors.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(16)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: - 보상 섹션
    private var rewardSection: some View {
        let rewards = boardVM.group.lineRewards.filter { !$0.isEmpty }
        let achieved = boardVM.completedLines.count
        let hasAnyReward = !rewards.isEmpty || !boardVM.group.allBingoReward.isEmpty

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Localization.Board.currentGoal)
                    .font(Paperlogy.black(20))
                    .foregroundStyle(BRColors.onSurface)
                Spacer()
                Button { showRewardEdit = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isLeader ? "pencil" : "eye")
                            .font(.system(size: 11, weight: .bold))
                        Text(isLeader ? Localization.Board.editReward : Localization.Board.viewReward)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(BRColors.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(BRColors.cyanDim)
                    .clipShape(Capsule())
                }
            }

            if !hasAnyReward {
                Text(isLeader ? Localization.Board.rewardHintLeader : Localization.Board.rewardHintMember)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BRColors.onSurfaceMuted)
                    .padding(.vertical, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(Array(boardVM.group.lineRewards.enumerated().filter { !$0.element.isEmpty }), id: \.offset) { i, reward in
                            RewardMilestoneCard(
                                index: i,
                                reward: reward,
                                isAllBingo: false,
                                state: i < achieved ? .achieved : (i == achieved ? .next : .pending)
                            )
                        }
                        if !boardVM.group.allBingoReward.isEmpty {
                            let allCellsComplete: Bool = {
                                guard let board = boardVM.board else { return false }
                                let memberIDs = boardVM.group.memberIDs
                                return board.cells.allSatisfy { $0.isCompleted(for: memberIDs) }
                            }()
                            RewardMilestoneCard(
                                index: -1,
                                reward: boardVM.group.allBingoReward,
                                isAllBingo: true,
                                state: allCellsComplete ? .achieved : .pending
                            )
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                }
            }

            // 내 진행률 바
            if let board = boardVM.board {
                let total = board.size * board.size
                let myCompleted = board.cells.filter { $0.completedBy.contains(memberID) }.count
                let ratio = total > 0 ? Double(myCompleted) / Double(total) : 0

                VStack(alignment: .leading, spacing: 5) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(BRColors.cyanDim).frame(height: 7)
                            Capsule()
                                .fill(BRColors.cyanGradient)
                                .frame(width: geo.size.width * ratio, height: 7)
                                .animation(.spring(duration: 0.5), value: ratio)
                        }
                    }
                    .frame(height: 7)
                    Text(Localization.Board.myProgress(myCompleted, total))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BRColors.cyan.opacity(0.8))
                }
            }
        }
        .padding(18)
        .background(BRColors.cyanDim)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - 빙고 그리드
    private func bingoGrid(board: BingoBoard) -> some View {
        let size = board.size
        return GeometryReader { geo in
            let gap: CGFloat = 6
            let cellSize = (geo.size.width - gap * CGFloat(size - 1)) / CGFloat(size)
            VStack(spacing: gap) {
                ForEach(0..<size, id: \.self) { row in
                    HStack(spacing: gap) {
                        ForEach(0..<size, id: \.self) { col in
                            let idx = row * size + col
                            BingoCellView(
                                cell: board.cell(row: row, col: col),
                                memberIDs: boardVM.group.memberIDs,
                                currentMemberID: memberID,
                                isLeader: isLeader,
                                completedLineColor: boardVM.completedLineCells[idx]
                                    .map { Self.lineColors[$0 % Self.lineColors.count] },
                                size: cellSize,
                                onTap: { selectedIndex = CellIndex(row: row, col: col) },
                                onEdit: { editingIndex = CellIndex(row: row, col: col) }
                            )
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - 멤버 현황
    private func memberSection(board: BingoBoard) -> some View {
        let total = board.size * board.size
        let memberIDs = boardVM.group.memberIDs

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(Localization.Board.memberStatus)
                    .font(Paperlogy.black(16))
                    .foregroundStyle(BRColors.onSurface)
                Spacer()
                Text(Localization.isEnglish ? "\(memberIDs.count) members" : "\(memberIDs.count)명")
                    .font(Paperlogy.black(16))
                    .foregroundStyle(BRColors.primary)
            }

            VStack(spacing: 12) {
                ForEach(Array(memberIDs.enumerated()), id: \.element) { idx, id in
                    let completed = board.cells.filter { $0.completedBy.contains(id) }.count
                    let color = memberColors[idx % memberColors.count]
                    let ratio = total > 0 ? CGFloat(completed) / CGFloat(total) : 0
                    let profile = boardVM.memberProfiles[id]
                    let isMe = id == memberID

                    VStack(spacing: 10) {
                        HStack(spacing: 14) {
                            // 프로필 이모지
                            ZStack {
                                Circle()
                                    .fill(color.opacity(0.15))
                                    .frame(width: 46, height: 46)
                                Text(profile?.profileEmoji ?? "😀")
                                    .font(.system(size: 24))
                                // 방장 크라운
                                if id == boardVM.group.leaderID {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 9))
                                                .foregroundStyle(BRColors.surfaceHigh)
                                                .offset(x: 4, y: -4)
                                        }
                                        Spacer()
                                    }
                                    .frame(width: 46, height: 46)
                                }
                            }

                            // 이름과 진행률 표시
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isMe ? Localization.Board.meWithName(profile?.displayName ?? "") : (profile?.displayName.isEmpty == false ? profile!.displayName : Localization.Board.memberN(idx + 1)))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(isMe ? color : BRColors.onSurface)
                                Text("\(completed)/\(total)")
                                    .font(Paperlogy.bold(13))
                                    .foregroundStyle(color)
                            }
                            Spacer()
                        }

                        // 진행률 바
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(BRColors.surfaceContainer)
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(color)
                                    .frame(width: geo.size.width * ratio, height: 8)
                                    .animation(.spring(duration: 0.5), value: ratio)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(isMe ? color.opacity(0.06) : BRColors.surfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(18)
        .background(BRColors.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - 보상 마일스톤 카드
enum RewardMilestoneState { case achieved, next, pending }

struct RewardMilestoneCard: View {
    let index: Int
    let reward: String
    let isAllBingo: Bool
    let state: RewardMilestoneState

    private var bgColor: Color {
        if isAllBingo && state == .achieved { return BRColors.cyan }
        switch state {
        case .achieved: return BRColors.cyan
        case .next:     return Color.white.opacity(0.85)
        case .pending:  return Color.white.opacity(0.5)
        }
    }
    private var textColor: Color {
        switch state {
        case .achieved: return .white
        case .next:     return BRColors.onSurface
        case .pending:  return BRColors.onSurfaceMuted
        }
    }
    private var labelColor: Color {
        if isAllBingo && state == .achieved { return .white.opacity(0.7) }
        switch state {
        case .achieved: return .white.opacity(0.7)
        case .next:     return BRColors.cyan
        case .pending:  return BRColors.onSurfaceMuted
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                if state == .achieved {
                    Image(systemName: isAllBingo ? "trophy.fill" : "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                } else if state == .next {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(BRColors.cyan)
                } else if isAllBingo {
                    Text("🏆")
                        .font(.system(size: 10))
                }
                Text(isAllBingo ? Localization.Board.allBingo : "\(index + 1) BINGO")
                    .font(Paperlogy.bold(10))
                    .foregroundStyle(labelColor)
                    .tracking(0.5)
            }
            Text(reward)
                .font(Paperlogy.black(14))
                .foregroundStyle(textColor)
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(width: 130, height: 72, alignment: .topLeading)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(
            color: state == .achieved ? BRColors.cyan.opacity(0.3) : .clear,
            radius: 8, y: 3
        )
    }
}

// MARK: - 보상 수정/확인 시트
struct RewardEditSheet: View {
    let size: Int
    let isReadOnly: Bool
    let onSave: ([String], String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var rewards: [String]
    @State private var allBingoReward: String

    init(rewards: [String], allBingoReward: String, size: Int, isReadOnly: Bool = false,
         onSave: @escaping ([String], String) -> Void) {
        self.size = size
        self.isReadOnly = isReadOnly
        self.onSave = onSave
        let padded = rewards + Array(repeating: "", count: max(0, size - rewards.count))
        _rewards = State(initialValue: Array(padded.prefix(size)))
        _allBingoReward = State(initialValue: allBingoReward)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BRColors.surface.ignoresSafeArea()
                Circle()
                    .fill(BRColors.cyanDim)
                    .frame(width: 180, height: 180)
                    .offset(x: 140, y: -160)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 헤더
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle().fill(BRColors.cyanDim).frame(width: 36, height: 36)
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(BRColors.cyan)
                            }
                            Text(isReadOnly ? Localization.Board.viewReward : Localization.Board.editReward)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(BRColors.onSurfaceMuted)
                        }
                        Text(isReadOnly ? Localization.Board.rewardViewTitle : Localization.Board.rewardEditTitle)
                            .font(Paperlogy.black(26))
                            .foregroundStyle(BRColors.onSurface)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 28)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            // 빙고 보상 n개
                            ForEach(0..<size, id: \.self) { i in
                                rewardRow(
                                    label: "\(i + 1)",
                                    placeholder: Localization.Board.bingoRewardN(i + 1),
                                    value: $rewards[i],
                                    accentColor: BRColors.cyan
                                )
                            }

                            // 올 빙고 특별 보상
                            Divider()
                                .padding(.vertical, 4)

                            rewardRow(
                                label: "🏆",
                                placeholder: Localization.Board.allBingoRewardPlaceholder,
                                value: $allBingoReward,
                                accentColor: BRColors.cyan
                            )
                            Text(Localization.Board.allBingoDesc)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(BRColors.onSurfaceMuted)
                                .padding(.horizontal, 4)
                        }
                        .padding(.horizontal, 24)
                    }

                    if !isReadOnly {
                        Button {
                            onSave(
                                rewards.map { $0.trimmingCharacters(in: .whitespaces) },
                                allBingoReward.trimmingCharacters(in: .whitespaces)
                            )
                            dismiss()
                        } label: {
                            Text(Localization.Board.save)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(BRColors.cyanGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 48))
                                .shadow(color: BRColors.cyan.opacity(0.3), radius: 16, y: 5)
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                    } else {
                        Spacer().frame(height: 24)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isReadOnly ? Localization.Board.close : Localization.Board.cancel) { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.cyan)
                }
            }
        }
    }

    @ViewBuilder
    private func rewardRow(label: String, placeholder: String, value: Binding<String>, accentColor: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(value.wrappedValue.isEmpty ? BRColors.surfaceContainer : accentColor)
                    .frame(width: 32, height: 32)
                Text(label)
                    .font(Paperlogy.black(13))
                    .foregroundStyle(value.wrappedValue.isEmpty ? BRColors.onSurfaceMuted : .white)
            }
            if isReadOnly {
                Text(value.wrappedValue.isEmpty ? Localization.Board.noReward : value.wrappedValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(value.wrappedValue.isEmpty ? BRColors.onSurfaceMuted : BRColors.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                TextField(placeholder, text: value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BRColors.onSurface)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(BRColors.cyanDim)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct CellIndex: Identifiable {
    let row: Int; let col: Int
    var id: String { "\(row)-\(col)" }
}

// MARK: - 빙고 달성 축하 오버레이

struct BingoCelebrationOverlay: View {
    let count: Int
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            ConfettiView(count: 60)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("🎉")
                    .font(.system(size: 64))

                VStack(spacing: 6) {
                    Text(Localization.Board.bingoAchieved(count))
                        .font(Paperlogy.black(38))
                        .foregroundStyle(BRColors.onSurface)
                    Text(Localization.Board.lineComplete)
                        .font(Paperlogy.medium(16))
                        .foregroundStyle(BRColors.onSurfaceMuted)
                }

                Button { animateOut() } label: {
                    Text(Localization.Board.confirm)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 120, height: 46)
                        .background(BRColors.primaryGradient)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 40)
            .background(BRColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: .black.opacity(0.2), radius: 40)
            .padding(.horizontal, 32)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1; opacity = 1
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func animateOut() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0; scale = 0.92
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onDismiss() }
    }
}

// MARK: - 전체 완성 오버레이

struct GameCompleteOverlay: View {
    let groupName: String
    let onContinue: () -> Void
    let onFinish: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            ConfettiView(count: 90)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Text("🏆")
                    .font(.system(size: 72))

                VStack(spacing: 8) {
                    Text(Localization.Board.allBingoComplete)
                        .font(Paperlogy.black(38))
                        .foregroundStyle(BRColors.onSurface)
                    Text(groupName)
                        .font(Paperlogy.bold(16))
                        .foregroundStyle(BRColors.primary)
                    Text(Localization.Board.allLineComplete)
                        .font(Paperlogy.medium(15))
                        .foregroundStyle(BRColors.onSurfaceMuted)
                }

                VStack(spacing: 10) {
                    Button(action: onContinue) {
                        Text(Localization.Board.continueGame)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(BRColors.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 48))
                            .shadow(color: BRColors.primary.opacity(0.3), radius: 12, y: 4)
                    }

                    Button(action: onFinish) {
                        Text(Localization.Board.quitGame)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(BRColors.onSurfaceMuted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                }
            }
            .padding(36)
            .background(BRColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .padding(.horizontal, 24)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                scale = 1; opacity = 1
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
