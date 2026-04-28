import SwiftUI

struct UserGuideView: View {
    @Environment(\.dismiss) var dismiss
    private var isEnglish: Bool { Localization.isEnglish }

    var body: some View {
        NavigationStack {
            ZStack {
                BRColors.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {

                        // 홈 화면
                        guideSection(
                            icon: "house.fill",
                            title: isEnglish ? "Home Screen" : "홈 화면",
                            items: isEnglish ? [
                                GuideItem(symbol: "plus.circle.fill",
                                          text: "Tap the '+' button at the bottom right to create a new bingo or join with an invite code. (Free users can create 1 room; Premium users can create unlimited rooms.)"),
                                GuideItem(symbol: "hand.tap.fill",
                                          text: "Tap a bingo room card to enter the bingo board."),
                                GuideItem(symbol: "ellipsis.circle.fill",
                                          text: "Long-press a bingo room card to copy the invite link or view bingo info.")
                            ] : [
                                GuideItem(symbol: "plus.circle.fill",
                                          text: "우측 하단의 '+' 버튼을 눌러 새 빙고를 만들거나, 초대 코드로 빙고에 참여할 수 있어요. (무료 사용자는 1개의 방 만들기, 유료 사용자는 무제한 가능)"),
                                GuideItem(symbol: "hand.tap.fill",
                                          text: "빙고 방 카드를 탭하면 빙고판으로 입장해요."),
                                GuideItem(symbol: "ellipsis.circle.fill",
                                          text: "빙고 방 카드를 길게 누르면 초대 링크 복사 및 빙고 정보를 확인할 수 있어요.")
                            ]
                        )

                        // 빙고 화면
                        guideSection(
                            icon: "square.grid.3x3.fill",
                            title: isEnglish ? "Bingo Board" : "빙고 화면",
                            items: isEnglish ? [
                                GuideItem(symbol: "crown.fill",
                                          text: "Only the leader can edit missions and set rewards. Tap the 'Edit Reward' button to set bingo rewards."),
                                GuideItem(symbol: "star.fill",
                                          text: "The 'Current Goal' section shows your next reward milestone and tracks progress."),
                                GuideItem(symbol: "hand.tap.fill",
                                          text: "Tap a cell to mark a mission as complete (or undo it)."),
                                GuideItem(symbol: "contextualmenu.and.cursorarrow",
                                          text: "Long-press a cell to quickly edit the mission (leader only) or toggle completion.")
                            ] : [
                                GuideItem(symbol: "crown.fill",
                                          text: "방장만 미션을 수정하고 보상을 설정할 수 있어요. '보상 수정' 버튼을 눌러 빙고 달성 보상을 입력해보세요."),
                                GuideItem(symbol: "star.fill",
                                          text: "'현재 목표' 섹션에서 다음 보상 목표와 진행 상황을 한눈에 확인할 수 있어요."),
                                GuideItem(symbol: "hand.tap.fill",
                                          text: "셀을 탭하면 미션 완료 체크 또는 취소를 할 수 있어요."),
                                GuideItem(symbol: "contextualmenu.and.cursorarrow",
                                          text: "셀을 길게 누르면 미션 수정(방장 전용) 또는 완료 체크를 빠르게 할 수 있어요.")
                            ]
                        )

                        // 이메일 문의
                        guideSection(
                            icon: "envelope.fill",
                            title: isEnglish ? "Contact Us" : "이메일 문의",
                            items: isEnglish ? [
                                GuideItem(symbol: "mail.fill",
                                          text: "Have questions or feedback? Feel free to reach out!\nyogotgam@gmail.com")
                            ] : [
                                GuideItem(symbol: "mail.fill",
                                          text: "문의사항이나 피드백이 있으시면 언제든지 연락해 주세요!\nyogotgam@gmail.com")
                            ]
                        )

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(Localization.Settings.userGuide)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(BRColors.onSurface)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.Settings.close) { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                }
            }
        }
    }

    @ViewBuilder
    private func guideSection(icon: String, title: String, items: [GuideItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 섹션 헤더
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(BRColors.primary)
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(BRColors.onSurface)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(BRColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 항목 목록
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(BRColors.primary)
                            .frame(width: 20, height: 20)
                            .padding(.top, 1)
                        Text(item.text)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(BRColors.onSurface)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(BRColors.surfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

private struct GuideItem: Identifiable {
    let id = UUID()
    let symbol: String
    let text: String
}
