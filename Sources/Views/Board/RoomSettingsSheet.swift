import SwiftUI
import UIKit
import UserNotifications

struct RoomSettingsSheet: View {
    let groupID: String
    let groupName: String
    let inviteCode: String
    let memberID: String

    @Environment(\.dismiss) var dismiss

    @State private var settings: NotificationSettings = NotificationSettings()
    @State private var isLoading = true
    @State private var systemAuthStatus: UNAuthorizationStatus = .notDetermined
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                BRColors.surface.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // 시스템 알림 비활성 안내 배너
                        if systemAuthStatus == .denied {
                            systemDisabledBanner
                        }

                        // 초대 코드 섹션
                        inviteCodeSection

                        // 알림 설정 섹션
                        notificationSection
                            .opacity(isLoading ? 0.5 : 1.0)
                            .disabled(isLoading)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(Localization.RoomSettings.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(BRColors.onSurface)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.RoomSettings.close) { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                }
            }
            .task {
                await loadSettings()
                await refreshAuthStatus()
            }
        }
    }

    // MARK: - 시스템 알림 비활성 배너

    private var systemDisabledBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(BRColors.tertiary)

            VStack(alignment: .leading, spacing: 4) {
                Text(Localization.RoomSettings.systemNotifDisabled)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(BRColors.onSurface)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text(Localization.RoomSettings.openSystemSettings)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(BRColors.primary)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(BRColors.tertiary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 초대 링크 공유 섹션

    private var inviteCodeSection: some View {
        Button {
            showShareSheet = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(BRColors.primary)
                    .frame(width: 32)
                Text(Localization.Home.shareInvite)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BRColors.onSurface)
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BRColors.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(BRColors.surfaceLow)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
    }

    private var shareText: String {
        if Localization.isEnglish {
            return "Join '\(groupName)' bingo room with code: \(inviteCode)"
        } else {
            return "빙고방 '\(groupName)'에 참여하세요! 초대 코드: \(inviteCode)"
        }
    }

    // MARK: - 알림 설정 섹션

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(BRColors.primary)
                Text(Localization.RoomSettings.notifications)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(BRColors.onSurfaceMuted)
            }
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                toggleRow(
                    icon: "🎯",
                    label: Localization.RoomSettings.notifMissionComplete,
                    isOn: Binding(
                        get: { settings.notifMissionComplete },
                        set: { settings.notifMissionComplete = $0; persist() }
                    )
                )
                Divider().opacity(0.3).padding(.leading, 56)
                toggleRow(
                    icon: "🎉",
                    label: Localization.RoomSettings.notifBingoAchieved,
                    isOn: Binding(
                        get: { settings.notifBingoAchieved },
                        set: { settings.notifBingoAchieved = $0; persist() }
                    )
                )
                Divider().opacity(0.3).padding(.leading, 56)
                toggleRow(
                    icon: "💬",
                    label: Localization.RoomSettings.notifReactionComment,
                    isOn: Binding(
                        get: { settings.notifReactionComment },
                        set: { settings.notifReactionComment = $0; persist() }
                    )
                )
                Divider().opacity(0.3).padding(.leading, 56)
                toggleRow(
                    icon: "👋",
                    label: Localization.RoomSettings.notifNewMember,
                    isOn: Binding(
                        get: { settings.notifNewMember },
                        set: { settings.notifNewMember = $0; persist() }
                    )
                )
            }
            .background(BRColors.surfaceLow)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(16)
        .background(BRColors.surfaceLow.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func toggleRow(icon: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Text(icon)
                .font(.system(size: 22))
                .frame(width: 32)
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(BRColors.onSurface)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(BRColors.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - 데이터 로드/저장

    private func loadSettings() async {
        let loaded = await NotificationService.shared.fetchSettings(
            groupID: groupID, memberID: memberID
        )
        self.settings = loaded
        self.isLoading = false
    }

    private func persist() {
        Task {
            await NotificationService.shared.saveSettings(
                settings, groupID: groupID, memberID: memberID
            )
        }
    }

    private func refreshAuthStatus() async {
        systemAuthStatus = await NotificationService.shared.currentAuthorizationStatus()
    }
}
