import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var groupVM = GroupViewModel()
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false

    private var memberID: String {
        authViewModel.currentMember?.id ?? Auth.auth().currentUser?.uid ?? ""
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                BRColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerView
                        groupListView
                            .padding(.top, 24)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                    }
                }

                // FAB
                Menu {
                    Button {
                        showCreateGroup = true
                    } label: {
                        Label("새 빙고 만들기", systemImage: "plus.square")
                    }
                    Button {
                        showJoinGroup = true
                    } label: {
                        Label("초대 코드로 참여", systemImage: "person.badge.plus")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(BRColors.orange)
                            .frame(width: 64, height: 64)
                            .shadow(color: BRColors.orange.opacity(0.4), radius: 12, y: 4)
                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(28)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupSheet(onCreated: { groupVM.fetchGroups(for: memberID) })
            }
            .sheet(isPresented: $showJoinGroup) {
                JoinGroupSheet(onJoined: { groupVM.fetchGroups(for: memberID) })
            }
        }
        .onAppear {
            if !memberID.isEmpty {
                groupVM.fetchGroups(for: memberID)
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        ZStack(alignment: .bottomLeading) {
            BRColors.cobaltBlue

            // 장식 도형
            Circle()
                .fill(BRColors.orange.opacity(0.7))
                .frame(width: 90, height: 90)
                .offset(x: UIScreen.main.bounds.width - 55, y: 20)

            Rectangle()
                .fill(BRColors.red.opacity(0.5))
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(20))
                .offset(x: UIScreen.main.bounds.width - 110, y: -10)

            Triangle()
                .fill(BRColors.beige.opacity(0.6))
                .frame(width: 50, height: 50)
                .offset(x: 24, y: -10)

            // 텍스트
            VStack(alignment: .leading, spacing: 6) {
                Text("BingoRingo")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text(authViewModel.currentMember?.displayName.isEmpty == false
                     ? "안녕하세요, \(authViewModel.currentMember!.displayName)!"
                     : "안녕하세요!")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Button(action: { authViewModel.signOut() }) {
                    Text("로그아웃")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    // MARK: - Group List
    private var groupListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("내 빙고")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(BRColors.darkText)
                Spacer()
                Text("\(groupVM.groups.count)개")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if groupVM.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if groupVM.groups.isEmpty {
                emptyView
            } else {
                ForEach(groupVM.groups) { group in
                    NavigationLink(destination: BoardView(group: group)) {
                        GroupCard(group: group, memberID: memberID)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(BRColors.lightGray.opacity(0.5))
                    .frame(height: 160)

                VStack(spacing: 12) {
                    // 미니 빙고 그리드 아이콘
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { _ in
                            VStack(spacing: 5) {
                                ForEach(0..<3, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(BRColors.lightGray)
                                        .frame(width: 18, height: 18)
                                }
                            }
                        }
                    }
                    Text("아직 빙고가 없어요\n+ 버튼으로 시작해보세요!")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

// MARK: - Group Card
struct GroupCard: View {
    let group: BingoGroup
    let memberID: String

    private let accentColors: [Color] = [
        BRColors.cobaltBlue, BRColors.orange, BRColors.red, BRColors.beige
    ]

    private var accentColor: Color {
        let idx = abs(group.id.hashValue) % accentColors.count
        return accentColors[idx]
    }

    var body: some View {
        HStack(spacing: 0) {
            // 컬러 사이드바
            Rectangle()
                .fill(accentColor)
                .frame(width: 6)

            HStack(spacing: 14) {
                // 미니 빙고 아이콘
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 50, height: 50)

                    VStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            HStack(spacing: 2) {
                                ForEach(0..<3, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(accentColor.opacity(0.5))
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(BRColors.darkText)

                    HStack(spacing: 8) {
                        Label("\(group.memberIDs.count)명", systemImage: "person.2.fill")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.secondary)

                        Text("·")
                            .foregroundStyle(.secondary)

                        Text("코드: \(group.inviteCode)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(accentColor)
                    }

                    if group.leaderID == memberID {
                        Text("방장")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentColor)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 16)
            .padding(.leading, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
