import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var groupVM = GroupViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                BRColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        headerView
                        groupListView
                    }
                    .padding()
                }

                // FAB 버튼
                Menu {
                    Button("새 빙고 만들기") { groupVM.showCreateGroup = true }
                    Button("초대 코드로 참여") { groupVM.showJoinGroup = true }
                } label: {
                    ZStack {
                        Circle()
                            .fill(BRColors.cobaltBlue)
                            .frame(width: 60, height: 60)
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                }
                .padding(24)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $groupVM.showCreateGroup) {
                CreateGroupSheet(groupVM: groupVM)
            }
            .sheet(isPresented: $groupVM.showJoinGroup) {
                JoinGroupSheet(groupVM: groupVM)
            }
        }
        .onAppear {
            if let id = authViewModel.currentMember?.id {
                groupVM.fetchGroups(for: id)
            }
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("안녕하세요 👋")
                    .font(BRTypography.caption)
                    .foregroundStyle(.secondary)
                Text(authViewModel.currentMember?.displayName ?? "")
                    .font(BRTypography.sectionTitle)
                    .foregroundStyle(BRColors.cobaltBlue)
            }
            Spacer()
            Button(action: { authViewModel.signOut() }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(BRColors.cobaltBlue)
                    .font(.title3)
            }
        }
        .padding(.top, 8)
    }

    private var groupListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("내 빙고")
                .font(BRTypography.sectionTitle)
                .foregroundStyle(.primary)

            if groupVM.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            } else if groupVM.groups.isEmpty {
                emptyView
            } else {
                ForEach(groupVM.groups) { group in
                    NavigationLink(destination: BoardView(group: group)) {
                        GroupCard(group: group)
                    }
                }
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(BRColors.lightGray)
                    .frame(height: 180)
                VStack(spacing: 12) {
                    Text("🎯")
                        .font(.system(size: 48))
                    Text("아직 빙고가 없어요\n+ 버튼으로 시작해보세요!")
                        .font(BRTypography.cellTitle)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
}

struct GroupCard: View {
    let group: BingoGroup

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(BRColors.cobaltBlue)
                    .frame(width: 56, height: 56)
                Text("🎯")
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(BRTypography.cellTitle)
                    .foregroundStyle(.primary)
                Text("멤버 \(group.memberIDs.count)명 · 코드: \(group.inviteCode)")
                    .font(BRTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(BRColors.cobaltBlue)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
}
