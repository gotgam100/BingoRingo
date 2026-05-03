import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var groupVM = GroupViewModel()
    @StateObject private var premiumManager = PremiumManager.shared
    @AppStorage("appLanguage") private var appLanguage: String = "한글"
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var showProfile = false
    @State private var showSettings = false
    @State private var showPremiumAlert = false
    @State private var editingGroup: BingoGroup?
    @State private var copiedCode: String?
    @State private var memberProfiles: [String: Member] = [:]

    private var memberID: String {
        authViewModel.currentMember?.id ?? Auth.auth().currentUser?.uid ?? ""
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                BRColors.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerView
                        groupListView
                            .padding(.top, 32)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 110)
                            .id(appLanguage)  // 언어 변경시 뷰 재구성
                    }
                }

                // FAB
                Menu {
                    Button {
                        let userGroupCount = groupVM.groups.filter { $0.leaderID == memberID }.count
                        if !premiumManager.isPremium && userGroupCount >= 1 {
                            showPremiumAlert = true
                        } else {
                            showCreateGroup = true
                        }
                    } label: {
                        Label(Localization.Home.createNewBingo, systemImage: "plus.square")
                    }
                    Button {
                        showJoinGroup = true
                    } label: {
                        Label(Localization.Home.joinWithCode, systemImage: "person.badge.plus")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(BRColors.primaryGradient)
                            .frame(width: 62, height: 62)
                            .shadow(color: BRColors.primary.opacity(0.4), radius: 20, y: 6)
                        Image(systemName: "plus")
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                    }
                }
                .padding(28)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupSheet(onCreated: { groupVM.fetchGroups(for: memberID) })
                    .environmentObject(groupVM)
            }
            .sheet(isPresented: $showJoinGroup) {
                JoinGroupSheet(onJoined: { groupVM.fetchGroups(for: memberID) })
            }
            .sheet(isPresented: $showProfile) {
                ProfileSheet()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $editingGroup) { group in
                EditGroupSheet(group: group, memberID: memberID) {
                    groupVM.fetchGroups(for: memberID)
                }
            }
            .alert(Localization.CreateGroup.premiumRequired, isPresented: $showPremiumAlert) {
                Button(Localization.CreateGroup.buyInSettings) {
                    showSettings = true
                }
                Button(Localization.CreateGroup.cancel, role: .cancel) {}
            } message: {
                Text(Localization.CreateGroup.premiumMessage)
            }
            .overlay(alignment: .top) {
                if copiedCode != nil {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BRColors.primary)
                        Text(Localization.Home.inviteCodeCopied)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BRColors.primary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(BRColors.primaryDim)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            if !memberID.isEmpty {
                groupVM.fetchGroups(for: memberID)
            }
        }
        .onChange(of: groupVM.groups) { _, groups in
            let allIDs = Array(Set(groups.flatMap { $0.memberIDs }))
            Task {
                let fetched = (try? await FirestoreService.shared.fetchMembers(ids: allIDs)) ?? [:]
                memberProfiles = fetched
            }
        }
        .onChange(of: authViewModel.currentMember) { _, member in
            guard let member, let id = member.id else { return }
            memberProfiles[id] = member
        }
    }

    // MARK: - Header
    private var headerView: some View {
        ZStack(alignment: .topTrailing) {
            // 배경 그라디언트
            Rectangle()
                .fill(BRColors.primaryGradient)
                .ignoresSafeArea(edges: .top)

            // 기하학적 장식 (배경에서 삐져나오는 형태)
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 200, height: 200)
                .offset(x: UIScreen.main.bounds.width - 60, y: -40)

            Blob1()
                .fill(Color.white.opacity(0.06))
                .frame(width: 140, height: 140)
                .offset(x: UIScreen.main.bounds.width - 160, y: 20)

            Circle()
                .fill(BRColors.surfaceHigh.opacity(0.25))
                .frame(width: 72, height: 72)
                .offset(x: 24, y: -30)

            // 설정 버튼 (상단 우측)
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 40, height: 40)
            }
            .padding(.top, 16)
            .padding(.trailing, 24)

            // 텍스트 + 프로필 (하단)
            VStack(alignment: .leading) {
                Spacer()

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Localization.isEnglish ? "Bingo To Do Together" : "다함께 빙고 To Do")
                            .font(Paperlogy.bold(13))
                            .foregroundStyle(.white.opacity(0.8))
                            .tracking(1.5)

                        Text({
                            let name = authViewModel.currentMember?.displayName ?? ""
                            if name.isEmpty { return Localization.Home.hello }
                            return Localization.isEnglish ? "Hi, \(name)!" : "\(name)님,\n안녕하세요!"
                        }())
                            .font(Paperlogy.black(26))
                            .foregroundStyle(.white)
                            .tracking(-0.5)
                    }

                    Spacer()

                    // 프로필 이모지 버튼
                    Button { showProfile = true } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 52, height: 52)
                            Text(authViewModel.currentMember?.profileEmoji ?? "😀")
                                .font(.system(size: 28))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .frame(height: 200)
    }

    // MARK: - Group List
    private var groupListView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(Localization.Home.myBingo)
                        .font(Paperlogy.black(24))
                        .foregroundStyle(BRColors.onSurface)
                        .tracking(-0.5)
                    if !groupVM.groups.isEmpty {
                        Text(Localization.isEnglish ? "\(groupVM.groups.count) \(Localization.Home.bingoCount)" : "\(groupVM.groups.count)\(Localization.Home.bingoCount)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(BRColors.onSurfaceMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(BRColors.surfaceLow)
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
                Text(Localization.isEnglish
                     ? "Create a room or enter another room's invite code."
                     : "방을 만들거나, 다른 방의 참여코드를 입력하세요.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(BRColors.onSurfaceMuted)
            }

            if groupVM.isLoading {
                ProgressView()
                    .tint(BRColors.primary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if groupVM.groups.isEmpty {
                emptyView
            } else {
                let sortedGroups = groupVM.groups.sorted {
                    $0.leaderID == memberID && $1.leaderID != memberID
                }
                ForEach(sortedGroups) { group in
                    NavigationLink(destination: BoardView(group: group, allGroups: groupVM.groups)) {
                        GroupCard(group: group, memberID: memberID, memberProfiles: memberProfiles)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            editingGroup = group
                        } label: {
                            Label(Localization.Home.viewBingoInfo, systemImage: "info.circle.fill")
                        }

                        Button {
                            UIPasteboard.general.string = group.inviteCode
                            copiedCode = group.inviteCode
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                copiedCode = nil
                            }
                        } label: {
                            Label(Localization.Home.copyInviteCode, systemImage: "doc.on.doc")
                        }
                    }
                }
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            // 장식용 미니 빙고 그리드
            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { col in
                            let colors: [Color] = [BRColors.primaryDim, BRColors.surfaceHigh, BRColors.primaryMid]
                            RoundedRectangle(cornerRadius: 6)
                                .fill(colors[(row * 3 + col) % colors.count])
                                .frame(width: 28, height: 28)
                        }
                    }
                }
            }

            VStack(spacing: 6) {
                Text(Localization.Home.emptyTitle)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(BRColors.onSurface)
                Text(Localization.Home.emptySubtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BRColors.onSurfaceMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(BRColors.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Group Card
struct GroupCard: View {
    let group: BingoGroup
    let memberID: String
    let memberProfiles: [String: Member]

    // 방장: 파랑 계열 / 참여자: 초록·보라·갈색 계열, 보드 크기로 구분
    private var accent: Color {
        if group.leaderID == memberID {
            return BRColors.primary
        }
        switch group.boardSize {
        case 3:  return BRColors.particleCyan
        case 4:  return Color(hex: "#8B2BE2")  // 보라
        default: return BRColors.particlePink
        }
    }
    private let memberColors: [Color] = [
        BRColors.primary, BRColors.particlePink, BRColors.particleCyan, Color(hex: "#8B2BE2")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 상단 컬러 헤더 (방장: 주황-노랑 / 멤버: 시안-하늘)
            ZStack(alignment: .bottomLeading) {
                Rectangle()
                    .fill(group.leaderID == memberID
                          ? AnyShapeStyle(BRColors.backgroundGradient)
                          : AnyShapeStyle(BRColors.memberGradient))

                // 장식 원 (배경에서 삐져나오는 효과)
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .offset(x: 220, y: -20)

                Circle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 60, height: 60)
                    .offset(x: 260, y: 20)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(Paperlogy.black(18))
                            .foregroundStyle(.white)

                        HStack(spacing: 6) {
                            if group.leaderID == memberID {
                                Text(Localization.Home.leader)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(BRColors.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.85))
                                    .clipShape(Capsule())
                            } else {
                                Text(Localization.Home.member)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(BRColors.particleCyan)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.85))
                                    .clipShape(Capsule())
                            }
                            if group.isCompleted {
                                HStack(spacing: 3) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 9, weight: .bold))
                                    Text(Localization.Board.complete)
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.white.opacity(0.25))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    Spacer()

                    // 빙고 수 (완료 시 트로피 표시)
                    VStack(spacing: 1) {
                        if group.isCompleted {
                            Text("🏆")
                                .font(.system(size: 28))
                        } else {
                            Text("\(group.completedLinesCount)")
                                .font(Paperlogy.black(30))
                                .foregroundStyle(.white)
                            Text("BINGO")
                                .font(Paperlogy.bold(8))
                                .foregroundStyle(.white.opacity(0.6))
                                .tracking(1)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .frame(height: 88)
            .clipped()

            // 하단 정보 (따뜻한 크림 배경)
            HStack(spacing: 0) {
                // 멤버 아바타
                VStack(alignment: .leading, spacing: 5) {
                    Text(Localization.Home.members)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(BRColors.onSurfaceMuted)
                    HStack(spacing: -6) {
                        let maxVisible = 5
                        let visible = Array(group.memberIDs.prefix(maxVisible))
                        let overflow = group.memberIDs.count - maxVisible

                        ForEach(Array(visible.enumerated()), id: \.element) { idx, id in
                            let color = memberColors[idx % memberColors.count]
                            let emoji = memberProfiles[id]?.profileEmoji ?? "😀"
                            ZStack {
                                Circle()
                                    .fill(color.opacity(0.18))
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().strokeBorder(BRColors.surfaceContainer, lineWidth: 1.5))
                                Text(emoji)
                                    .font(.system(size: 16))
                            }
                        }

                        if overflow > 0 {
                            ZStack {
                                Circle()
                                    .fill(BRColors.surfaceHigh)
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().strokeBorder(BRColors.surfaceContainer, lineWidth: 1.5))
                                Text("+\(overflow)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(BRColors.onSurfaceMuted)
                            }
                        }
                    }
                }

                Spacer()

                // 보드 사이즈
                VStack(spacing: 3) {
                    Text("\(group.boardSize)×\(group.boardSize)")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(accent)
                    Text(Localization.Home.boardSize)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(BRColors.onSurfaceMuted)
                }

                Spacer()

                // 초대코드
                VStack(spacing: 3) {
                    Text(group.inviteCode)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(accent)
                    Text(Localization.CreateGroup.inviteCode)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(BRColors.onSurfaceMuted)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BRColors.onSurfaceMuted)
                    .padding(.leading, 14)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(BRColors.surfaceContainer)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: BRColors.onSurface.opacity(0.07), radius: 24, x: 0, y: 6)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var premiumManager = PremiumManager.shared
    @AppStorage("appLanguage") private var selectedLanguage: String = "한글"
    @State private var showPremiumPopup = false
    @State private var showUserGuide = false

    var body: some View {
        NavigationStack {
            ZStack {
                BRColors.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 헤더
                        HStack(spacing: 12) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(BRColors.primary)

                            Text(Localization.Settings.title)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(BRColors.onSurface)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 32)

                        VStack(spacing: 12) {
                            // 프리미엄
                            VStack(alignment: .leading, spacing: 10) {
                                Button {
                                    showPremiumPopup = true
                                } label: {
                                    if !premiumManager.isPremium {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(Localization.Settings.premiumTitle)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundStyle(BRColors.onSurface)
                                                Text(Localization.Settings.premiumDesc)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundStyle(BRColors.onSurfaceMuted)
                                            }
                                            Spacer()
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundStyle(BRColors.primary)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(BRColors.primaryDim)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    } else {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(Localization.Settings.premiumMember)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundStyle(Color(hex: "#7A5500"))
                                                if let date = premiumManager.purchaseDate {
                                                    Text(Localization.Settings.purchaseDate + date.formatted(date: .abbreviated, time: .omitted))
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundStyle(Color(hex: "#7A5500").opacity(0.7))
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundStyle(Color(hex: "#B8860B"))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            LinearGradient(
                                                colors: [Color(hex: "#FFE066"), Color(hex: "#FFD700")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .shadow(color: Color(hex: "#FFD700").opacity(0.4), radius: 8, y: 3)
                                    }
                                }
                            }

                            // 언어 설정
                            settingSection(title: Localization.Settings.language) {
                                HStack {
                                    Text(Localization.Settings.languageSelect)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(BRColors.onSurface)
                                    Spacer()
                                    Menu {
                                        Button {
                                            selectedLanguage = "한글"
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                dismiss()
                                            }
                                        } label: {
                                            HStack {
                                                Text("한글")
                                                if selectedLanguage == "한글" {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                        Button {
                                            selectedLanguage = "English"
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                dismiss()
                                            }
                                        } label: {
                                            HStack {
                                                Text("English")
                                                if selectedLanguage == "English" {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    } label: {
                                        Text(selectedLanguage)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(BRColors.primary)
                                            .frame(width: 70, alignment: .trailing)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(BRColors.surfaceLow)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            // 앱 정보
                            settingSection(title: Localization.Settings.appInfo) {
                                VStack(spacing: 10) {
                                    settingRow(label: Localization.Settings.userGuide, icon: "book.fill") {
                                        showUserGuide = true
                                    }

                                    settingRow(label: Localization.Settings.appStore, icon: "star.fill") {
                                        if let url = URL(string: "itms-apps://apps.apple.com/app/id6764120536") {
                                            UIApplication.shared.open(url)
                                        }
                                    }

                                    settingRowInfo(label: Localization.Settings.appVersion, value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "", icon: "info.circle.fill")
                                }
                            }

                            // 이용약관 및 정책
                            settingSection(title: Localization.Settings.terms) {
                                VStack(spacing: 10) {
                                    settingRow(label: Localization.Settings.termsOfService, icon: "doc.text") {
                                        if let url = URL(string: "https://gotgam100.github.io/BingoRingo/terms.html") {
                                            UIApplication.shared.open(url)
                                        }
                                    }

                                    settingRow(label: Localization.Settings.privacy, icon: "lock.shield") {
                                        if let url = URL(string: "https://gotgam100.github.io/BingoRingo/privacy.html") {
                                            UIApplication.shared.open(url)
                                        }
                                    }

                                    settingRow(label: Localization.Settings.openSource, icon: "book") {
                                        if let url = URL(string: "https://gotgam100.github.io/BingoRingo/licenses.html") {
                                            UIApplication.shared.open(url)
                                        }
                                    }

                                    settingRow(label: Localization.Settings.support, icon: "envelope") {
                                        if let url = URL(string: "https://gotgam100.github.io/BingoRingo/support.html") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.Settings.close) { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                }
            }
            .sheet(isPresented: $showPremiumPopup) {
                PremiumPurchasePopup(premiumManager: premiumManager, isPresented: $showPremiumPopup)
            }
            .sheet(isPresented: $showUserGuide) {
                UserGuideView()
            }
        }
    }

    @ViewBuilder
    private func settingSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BRColors.onSurfaceMuted)
                .tracking(0.5)

            content()
        }
    }

    @ViewBuilder
    private func settingRowInfo(label: String, value: String = "", icon: String = "") -> some View {
        HStack {
            if !icon.isEmpty {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BRColors.primary)
                    .frame(width: 24)
            }

            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BRColors.onSurface)

            Spacer()

            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(BRColors.onSurfaceMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(BRColors.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func settingRow(label: String, value: String = "", icon: String = "", action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            HStack {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                        .frame(width: 24)
                }

                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BRColors.onSurface)

                Spacer()

                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(BRColors.onSurfaceMuted)
                }

                if !icon.isEmpty || !value.isEmpty {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BRColors.onSurfaceMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(BRColors.surfaceLow)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Premium Purchase Popup

struct PremiumPurchasePopup: View {
    @ObservedObject var premiumManager: PremiumManager
    @Binding var isPresented: Bool
    @State private var errorMessage: String? = nil
    @State private var restoreAlertMessage: String? = nil
    @State private var showRestoreAlert: Bool = false

    private var priceLabel: String {
        if let product = premiumManager.product {
            return Localization.isEnglish
                ? "Buy for \(product.displayPrice)"
                : "\(product.displayPrice)으로 구매"
        }
        return Localization.isEnglish ? Localization.Settings.buyNow : "1,100원으로 구매"
    }

    private var isPurchasing: Bool {
        premiumManager.purchaseState == .purchasing
    }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(BRColors.primary)

                Text(Localization.Settings.premiumTitle)
                    .font(Paperlogy.black(28))
                    .foregroundStyle(BRColors.onSurface)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 프리미엄 혜택
                    VStack(alignment: .leading, spacing: 12) {
                        Text(Localization.Settings.benefitTitle)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(BRColors.onSurfaceMuted)
                            .tracking(0.5)

                        VStack(alignment: .leading, spacing: 10) {
                            benefitRow(icon: "plus.circle.fill", text: Localization.Settings.benefit1)
                            benefitRow(icon: "sparkles", text: Localization.Settings.benefit2)
                        }
                    }

                    // 가격
                    VStack(alignment: .leading, spacing: 12) {
                        Text(Localization.Settings.priceTitle)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(BRColors.onSurfaceMuted)
                            .tracking(0.5)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(premiumManager.product?.displayPrice ?? (Localization.isEnglish ? "-" : "1,100원"))
                                    .font(Paperlogy.black(28))
                                    .foregroundStyle(BRColors.primary)
                                Text(Localization.Settings.oneTimePurchase)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(BRColors.onSurfaceMuted)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(BRColors.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(BRColors.primaryDim)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // 에러 메시지
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BRColors.tertiary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
            }

            // 버튼
            VStack(spacing: 12) {
                if premiumManager.isPremium {
                    Button { isPresented = false } label: {
                        Text(Localization.Settings.close)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(BRColors.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 48))
                            .shadow(color: BRColors.primary.opacity(0.3), radius: 16, y: 5)
                    }
                } else {
                    Button {
                        errorMessage = nil
                        Task {
                            await premiumManager.purchasePremium()
                            if case .failed(let msg) = premiumManager.purchaseState {
                                errorMessage = msg
                            } else if premiumManager.isPremium {
                                isPresented = false
                            }
                        }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(priceLabel)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(isPurchasing ? AnyShapeStyle(BRColors.surfaceContainer) : AnyShapeStyle(BRColors.primaryGradient))
                        .clipShape(RoundedRectangle(cornerRadius: 48))
                        .shadow(color: isPurchasing ? .clear : BRColors.primary.opacity(0.3), radius: 16, y: 5)
                    }
                    .disabled(isPurchasing)

                    Button { isPresented = false } label: {
                        Text(Localization.Settings.cancel)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(BRColors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(BRColors.surfaceContainer)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        Task {
                            let restored = await premiumManager.restorePurchases()
                            if restored {
                                restoreAlertMessage = Localization.isEnglish
                                    ? "Premium has been restored."
                                    : "프리미엄이 복원되었습니다."
                            } else {
                                restoreAlertMessage = Localization.isEnglish
                                    ? "No purchase history found."
                                    : "구매 내역을 찾을 수 없습니다."
                            }
                            showRestoreAlert = true
                        }
                    } label: {
                        Text(Localization.Settings.restorePurchase)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BRColors.onSurfaceMuted)
                    }
                    .alert(restoreAlertMessage ?? "", isPresented: $showRestoreAlert) {
                        Button(Localization.Settings.close, role: .cancel) {
                            if premiumManager.isPremium { isPresented = false }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(BRColors.surface)
    }

    @ViewBuilder
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BRColors.primary)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BRColors.onSurface)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(BRColors.surfaceLow)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
