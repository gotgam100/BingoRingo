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
                            .padding(.top, 28)
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
                            .fill(BRColors.red)
                            .frame(width: 64, height: 64)
                            .shadow(color: BRColors.red.opacity(0.35), radius: 14, y: 5)
                        Image(systemName: "plus")
                            .font(.title2.weight(.black))
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
            BRColors.blue

            // blob 장식
            Blob2()
                .fill(BRColors.red.opacity(0.6))
                .frame(width: 160, height: 160)
                .offset(x: UIScreen.main.bounds.width - 80, y: 30)

            Circle()
                .fill(BRColors.yellow.opacity(0.5))
                .frame(width: 60, height: 60)
                .offset(x: UIScreen.main.bounds.width - 160, y: -10)

            Blob1()
                .fill(BRColors.green.opacity(0.4))
                .frame(width: 90, height: 90)
                .offset(x: 20, y: -20)

            // 텍스트
            VStack(alignment: .leading, spacing: 6) {
                Text("BingoRingo")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .tracking(2)
                Text(authViewModel.currentMember?.displayName.isEmpty == false
                     ? "\(authViewModel.currentMember!.displayName)님, 안녕하세요!"
                     : "안녕하세요!")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Button(action: { authViewModel.signOut() }) {
                    Text("로그아웃")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(height: 185)
    }

    // MARK: - Group List
    private var groupListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("내 빙고")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(BRColors.primary)
                Spacer()
                if !groupVM.groups.isEmpty {
                    Text("\(groupVM.groups.count)개")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(BRColors.secondary)
                }
            }

            if groupVM.isLoading {
                ProgressView().frame(maxWidth: .infinity, minHeight: 120)
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
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(BRColors.cream)
                .shadow(color: .black.opacity(0.04), radius: 8)
                .frame(height: 170)

            VStack(spacing: 14) {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { col in
                        VStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { row in
                                let colors: [Color] = [BRColors.red, BRColors.blue, BRColors.yellow, BRColors.green, BRColors.lightGray]
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(colors[(row * 3 + col) % colors.count].opacity(0.5))
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
                Text("아직 빙고가 없어요\n+ 버튼으로 시작해보세요!")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(BRColors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Group Card
struct GroupCard: View {
    let group: BingoGroup
    let memberID: String

    private let accentColors: [Color] = [BRColors.blue, BRColors.red, BRColors.green, BRColors.yellow]
    private var accent: Color { accentColors[abs(group.id.hashValue) % accentColors.count] }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(accent)
                .frame(width: 5)

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accent.opacity(0.1))
                        .frame(width: 52, height: 52)
                    VStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { _ in
                            HStack(spacing: 3) {
                                ForEach(0..<3, id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(accent.opacity(0.45))
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(group.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(BRColors.primary)

                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(BRColors.secondary)
                        Text("\(group.memberIDs.count)명")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(BRColors.secondary)
                        Text("·")
                            .foregroundStyle(BRColors.secondary)
                        Text(group.inviteCode)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(accent)
                    }

                    if group.leaderID == memberID {
                        Text("방장")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(accent)
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(BRColors.secondary)
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 16)
            .padding(.leading, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(BRColors.cream)
                .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
